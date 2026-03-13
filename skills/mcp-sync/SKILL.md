---
name: mcp-sync
description: >
  Synchronizes MCP server tools with workspace-scoped custom agent files.
  Use this when MCP servers have been added or changed in the project and you
  want the workspace agent files in .github/agents/ to reflect the newly
  available tools — in both their YAML frontmatter and their system-prompt body.
  Invoke with /mcp-sync, or ask Copilot to "sync my agents with MCP tools".
---

You are running the **mcp-sync** skill. Follow the steps below precisely.

## Goal

Read the project's MCP server configuration, discover what tools each server exposes, and update every workspace-scoped custom agent file so that:

1. The agent's `tools:` YAML frontmatter array includes the MCP tools that are relevant to it.
2. A managed `## MCP Tools Available` block inside the agent's body describes those tools.

---

## Step 1 — Discover MCP Configuration

Search for MCP config files in the following order (stop at the first one found):

1. `.vscode/mcp.json` in the current workspace root
2. `~/.vscode/mcp.json` (user-level VS Code config)
3. `~/.config/Code - Insiders/User/mcp.json`
4. `~/.config/Code/User/mcp.json`

Parse the file. The `servers` object keys are server names; each entry has `command`, `args`, and optionally `env`.

Example structure:
```json
{
  "servers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${env:GITHUB_TOKEN}" }
    }
  }
}
```

If no config is found, stop and inform the user.

---

## Step 2 — Introspect Each Server's Tools

For each server in the config, run the `mcp-introspect.sh` helper script (located alongside this `SKILL.md`) to get the tool list:

```bash
bash .github/skills/mcp-sync/mcp-introspect.sh <command> [arg1 arg2 ...]
```

The script outputs a JSON array of tool objects:
```json
[
  {
    "name": "create_pull_request",
    "description": "Creates a pull request in a GitHub repository.",
    "inputSchema": { ... }
  }
]
```

If the script exits non-zero (timeout, auth error, etc.), skip that server with a warning note and continue.

**MCP tool IDs** follow the convention: `<server-name>/<tool-name>`
Example: `github/create_pull_request`

---

## Step 3 — Analyse Each Agent

Read every `.agent.md` file in `.github/agents/`. For each agent, extract:
- The `description` field from YAML frontmatter
- The agent's system-prompt body (role, responsibilities, workflow)

For each MCP tool discovered, assess whether it is relevant to the agent by considering:
- **Role alignment**: Does the tool's domain (git, search, web, DB, cloud, etc.) match the agent's responsibilities?
- **Workflow fit**: Would the agent ever need to call this tool to complete its tasks?

Apply conservative matching — only include a tool if it is genuinely useful for the agent. When in doubt, **exclude**.

---

## Step 4 — Update Agent Files

For each agent file, make two targeted edits:

### 4a — Frontmatter `tools:` list

Add relevant MCP tool IDs to the existing `tools:` array. Rules:
- **Preserve** all existing entries (never remove non-MCP tools)
- **Deduplicate** (skip if the tool ID is already present)
- Format: append to the array, e.g. `'github/create_pull_request'`

### 4b — Managed `## MCP Tools Available` block

Locate the markers `<!-- mcp-sync:begin -->` and `<!-- mcp-sync:end -->` in the file.
- If found: replace the content between them (inclusive of the markers).
- If not found: insert the block just before the first `<workflow>` tag, or the first `##` heading, or at the end of the file if neither exists.

The block format:
```markdown
<!-- mcp-sync:begin -->
## MCP Tools Available

The following tools are provided by MCP servers configured in this project.
Use them when appropriate for your tasks.

### `github/create_pull_request`
Creates a pull request in a GitHub repository. Use when implementation is complete and changes are ready for review.

### `github/search_repositories`
Searches GitHub repositories. Use when researching external dependencies or finding reference implementations.

<!-- mcp-sync:end -->
```

If the agent has no relevant MCP tools, insert an empty block with a note:
```markdown
<!-- mcp-sync:begin -->
<!-- mcp-sync: no MCP tools assigned to this agent -->
<!-- mcp-sync:end -->
```

---

## Step 5 — Report Changes

After updating all agents, print a structured summary:

```
mcp-sync complete
═══════════════════════════════════════════

Servers introspected: github (12 tools), postgres (8 tools)
Servers skipped:      slack (auth required)

Agent updates:
  Atlas.agent.md
    + github/create_pull_request
    + github/list_pull_requests
    ✓ ## MCP Tools Available block updated

  Sisyphus-subagent.agent.md
    + postgres/query
    + postgres/list_tables
    ✓ ## MCP Tools Available block updated

  Oracle-subagent.agent.md   — no changes (no relevant tools found)
  Explorer-subagent.agent.md — no changes (no relevant tools found)

Unmapped tools (review manually):
  github/manage_notifications — not mapped to any agent
```

---

## Rules

- **Idempotent**: Running mcp-sync twice produces no additional changes.
- **Non-destructive**: Never delete or overwrite content outside the managed block.
- **Minimal diffs**: Only write files that actually changed.
- **Respect agent boundaries**: Do not add tools that conflict with an agent's stated scope (e.g., don't add edit tools to a read-only explorer agent).
