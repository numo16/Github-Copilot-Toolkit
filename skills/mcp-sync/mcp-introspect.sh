#!/usr/bin/env bash
# mcp-introspect.sh — List tools exposed by an MCP server via JSON-RPC
#
# Usage:
#   bash mcp-introspect.sh <command> [arg1 arg2 ...]
#
# Starts the MCP server process, sends initialize + tools/list JSON-RPC
# messages, prints a JSON array of tool objects to stdout, then terminates.
#
# Exit codes:
#   0 — success, JSON array printed to stdout
#   1 — error (timeout, parse failure, server did not respond)
#
# Example:
#   bash mcp-introspect.sh npx -y @modelcontextprotocol/server-github
#   bash mcp-introspect.sh uvx mcp-server-git --repository /path/to/repo

set -euo pipefail

TIMEOUT_SECONDS="${MCP_INTROSPECT_TIMEOUT:-10}"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <command> [args...]" >&2
  exit 1
fi

# ── Build JSON-RPC messages ────────────────────────────────────────────────────

INIT_MSG=$(cat <<'EOF'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"mcp-introspect","version":"1.0.0"}}}
EOF
)

INITIALIZED_NOTIF='{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}'

LIST_TOOLS_MSG=$(cat <<'EOF'
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
EOF
)

# ── Run server and capture tools/list response ────────────────────────────────

TMPOUT=$(mktemp /tmp/mcp_introspect_out_XXXXXX)
TMPERR=$(mktemp /tmp/mcp_introspect_err_XXXXXX)

cleanup() {
  rm -f "$TMPOUT" "$TMPERR"
  # Kill server if still running
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Start server with stdin/stdout piped
# Use coproc to manage bidirectional communication
coproc SERVER { "$@" 2>"$TMPERR"; }
SERVER_PID=$SERVER_PID

# Send initialize
printf '%s\n' "$INIT_MSG" >&"${SERVER[1]}"

# Read initialize response (with timeout)
INIT_RESPONSE=""
DEADLINE=$((SECONDS + TIMEOUT_SECONDS))
while [[ $SECONDS -lt $DEADLINE ]]; do
  if read -t 1 -r line <&"${SERVER[0]}" 2>/dev/null; then
    if echo "$line" | grep -q '"id":1'; then
      INIT_RESPONSE="$line"
      break
    fi
  fi
done

if [[ -z "$INIT_RESPONSE" ]]; then
  echo "Error: MCP server did not respond to initialize within ${TIMEOUT_SECONDS}s" >&2
  exit 1
fi

# Send initialized notification
printf '%s\n' "$INITIALIZED_NOTIF" >&"${SERVER[1]}"

# Send tools/list
printf '%s\n' "$LIST_TOOLS_MSG" >&"${SERVER[1]}"

# Read tools/list response (with timeout)
TOOLS_RESPONSE=""
DEADLINE=$((SECONDS + TIMEOUT_SECONDS))
while [[ $SECONDS -lt $DEADLINE ]]; do
  if read -t 1 -r line <&"${SERVER[0]}" 2>/dev/null; then
    if echo "$line" | grep -q '"id":2'; then
      TOOLS_RESPONSE="$line"
      break
    fi
  fi
done

if [[ -z "$TOOLS_RESPONSE" ]]; then
  echo "Error: MCP server did not respond to tools/list within ${TIMEOUT_SECONDS}s" >&2
  exit 1
fi

# ── Extract tools array from response ─────────────────────────────────────────

# Use python3 to parse the JSON response and extract the tools array cleanly.
# Falls back to a minimal jq-based approach if python3 is unavailable.
if command -v python3 &>/dev/null; then
  echo "$TOOLS_RESPONSE" | python3 - <<'PYEOF'
import json, sys

raw = sys.stdin.read().strip()
try:
    response = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"Error: failed to parse MCP response as JSON: {e}", file=sys.stderr)
    sys.exit(1)

if "error" in response:
    err = response["error"]
    print(f"Error: MCP server returned error: {err.get('message', err)}", file=sys.stderr)
    sys.exit(1)

tools = response.get("result", {}).get("tools", [])

# Emit a clean JSON array with only the fields we care about
output = []
for t in tools:
    entry = {
        "name": t.get("name", ""),
        "description": t.get("description", ""),
    }
    if "inputSchema" in t:
        entry["inputSchema"] = t["inputSchema"]
    output.append(entry)

print(json.dumps(output, indent=2))
PYEOF
elif command -v jq &>/dev/null; then
  echo "$TOOLS_RESPONSE" | jq '.result.tools // []'
else
  echo "Error: neither python3 nor jq is available to parse the MCP response." >&2
  echo "Install python3 or jq and retry." >&2
  exit 1
fi
