# Copilot CLI Hooks

This directory is a placeholder for [GitHub Copilot CLI hooks](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-hooks).

## What are hooks?

Hooks run your own shell logic at specific points in the Copilot CLI session lifecycle. They give you programmatic control that skills and custom instructions cannot: blocking tool calls, enforcing guardrails, logging session activity, or customising error-recovery behaviour.

## Hook lifecycle events

| Hook name | When it fires |
|-----------|--------------|
| `sessionStart` | Once, at the beginning of a CLI session |
| `sessionEnd` | Once, at the end of a CLI session |
| `userPromptSubmitted` | Each time the user submits a prompt |
| `preToolUse` | Before any tool runs (can block the tool) |
| `postToolUse` | After any tool completes |
| `errorOccurred` | When an error is raised |
| `agentStop` | When the main agent finishes without error |
| `subagentStop` | When a subagent completes |

## Hook locations

| Scope | Path |
|-------|------|
| **Personal (shared across projects)** | `~/.copilot/hooks/` |
| **Project (workspace-specific)** | `.github/hooks/` |

## Hook script format

Hooks are shell scripts. Copilot CLI discovers them by hook name:

```
~/.copilot/hooks/
  sessionStart.sh
  preToolUse.sh
  postToolUse.sh
```

Each script is called with relevant context passed as environment variables. See the [official docs](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-hooks) for the full list of variables per event.

## Example: `preToolUse` guardrail

Block `bash` from running any `rm -rf` command:

```bash
#!/usr/bin/env bash
# ~/.copilot/hooks/preToolUse.sh

if [[ "$COPILOT_TOOL_NAME" == "bash" ]]; then
  if echo "$COPILOT_TOOL_INPUT" | grep -qE 'rm\s+-rf'; then
    echo "BLOCK: rm -rf is not allowed." >&2
    exit 1
  fi
fi

exit 0
```

## Example: `sessionEnd` transcript archiver

```bash
#!/usr/bin/env bash
# ~/.copilot/hooks/sessionEnd.sh

TRANSCRIPT_DIR="$HOME/.copilot/transcripts"
mkdir -p "$TRANSCRIPT_DIR"
echo "$COPILOT_SESSION_TRANSCRIPT" > "$TRANSCRIPT_DIR/$(date +%Y%m%d-%H%M%S).txt"
```

## Example: `errorOccurred` retry policy

```bash
#!/usr/bin/env bash
# ~/.copilot/hooks/errorOccurred.sh

# Automatically retry on rate-limit errors (up to 3 times)
if echo "$COPILOT_ERROR_MESSAGE" | grep -qi "rate limit"; then
  if [[ "${COPILOT_RETRY_COUNT:-0}" -lt 3 ]]; then
    sleep 5
    echo "RETRY"
    exit 0
  fi
fi

exit 0
```

## Adding hooks to a project

Install the toolkit with hooks support (adds this directory to `.github/hooks/`):

```bash
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh \
  | bash -s -- --scope=workspace --components=hooks
```

Then add your hook scripts to `.github/hooks/` and commit them with the rest of your agent files.
