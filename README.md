# GitHub Copilot Toolkit

A personal developer toolkit for [GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli) and [VS Code Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot). Delivers a curated set of custom agents, skills, workspace instructions, and hook documentation — all installable with a single curl command into any new project.

> Built upon the multi-agent orchestration foundation of [copilot-orchestra](https://github.com/ShepAlderson/copilot-orchestra) by ShepAlderson, with agent naming conventions inspired by [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode).

> **Note:** Best supported on VS Code Insiders (as of early 2026) for access to the latest agent and skill features.

---

## What's in the toolkit

```
Github-Copilot-Atlas/
├── agents/                              # Custom agents (.agent.md)
│   ├── Atlas.agent.md                   # Orchestrator: full dev lifecycle
│   ├── Prometheus.agent.md              # Autonomous planner
│   ├── Oracle-subagent.agent.md         # Deep researcher
│   ├── Explorer-subagent.agent.md       # Rapid codebase scout
│   ├── Sisyphus-subagent.agent.md       # TDD implementer
│   ├── Code-Review-subagent.agent.md    # Code reviewer
│   └── Frontend-Engineer-subagent.agent.md  # UI/UX specialist
├── skills/
│   ├── mcp-sync/                        # Agent Skill: sync MCP tools → agent files
│   │   ├── SKILL.md                     # Skill instructions
│   │   └── mcp-introspect.sh            # Helper: lists tools from an MCP server
│   └── skill-creator/                   # Agent Skill: create new skills for this toolkit
│       └── SKILL.md                     # Skill instructions
├── instructions/
│   └── copilot-instructions.md          # Custom instructions template
└── hooks/
    └── README.md                        # Copilot CLI hook documentation & examples
```

---

## Quick install

### ⚡ One-liner (all components, recommended)

**macOS / Linux:**
```bash
# User scope — available in all projects on this machine
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash

# Workspace scope — install into current project's .github/ (committable to version control)
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash -s -- --scope=workspace
```

**Windows (PowerShell):**
```powershell
# User scope
irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1 | iex

# Workspace scope
$s = irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1
& ([scriptblock]::Create($s)) -Scope workspace
```

### Selective install

Use `--components` to install only what you need:

```bash
# Agents + mcp-sync skill only
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh \
  | bash -s -- --scope=workspace --components=agents,skills

# Just the instructions template
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh \
  | bash -s -- --scope=workspace --components=instructions
```

| `--components` value | What it installs |
|----------------------|-----------------|
| `agents` | All 7 custom agent `.agent.md` files |
| `skills` | `mcp-sync` and `skill-creator` skill directories |
| `instructions` | `copilot-instructions.md` template |
| `hooks` | Hook documentation (`hooks/README.md`) |
| `all` (default) | Everything above |

### Installation destinations

| Component | User scope | Workspace scope |
|-----------|-----------|----------------|
| agents | VS Code User prompts dir | `.github/agents/` |
| skills | `~/.copilot/skills/mcp-sync/` and `~/.copilot/skills/skill-creator/` | `.github/skills/mcp-sync/` and `.github/skills/skill-creator/` |
| instructions | `~/.copilot/copilot-instructions.md` | `.github/copilot-instructions.md` |
| hooks | `~/.copilot/hooks/` | `.github/hooks/` |

### 💬 Let Copilot install it

Paste this into any VS Code Copilot Chat session:

```
Install the GitHub Copilot Toolkit by following the instructions here:
https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.md
```

---

## Agents

The agents follow a conductor-delegate pattern, enabling context-efficient parallel workflows across the full development lifecycle: **Plan → Implement → Review → Commit**.

### Primary agents

| Agent | Model | Role |
|-------|-------|------|
| **Atlas** (`Atlas.agent.md`) | Claude Sonnet 4.5 | ORCHESTRATOR — coordinates the full dev lifecycle, delegates to subagents, manages phase tracking and approval gates |
| **Prometheus** (`Prometheus.agent.md`) | Claude Sonnet 4.5 | AUTONOMOUS PLANNER — researches requirements, writes TDD-driven plans, hands off to Atlas |

### Subagents

| Agent | Model | Role |
|-------|-------|------|
| **Oracle** | Gemini 3 Flash | Deep researcher — gathers comprehensive context, can delegate to Explorer for large scopes |
| **Explorer** | Gemini 3 Flash | Rapid codebase scout — read-only, 3-10 parallel searches per batch, returns structured results |
| **Sisyphus** | Claude Sonnet 4.5 | TDD implementer — tests first, minimal code, lint/format, can run in parallel for disjoint work |
| **Code-Review** | Claude Sonnet 4.5 | Reviewer — structured APPROVED / NEEDS_REVISION / FAILED feedback |
| **Frontend-Engineer** | Claude Sonnet 4.5 | UI/UX specialist — components, styling, responsive design, accessibility |

### Why subagents? Context conservation.

Each subagent runs in its own isolated context window. This dramatically reduces token consumption in the main orchestrator:

- **Oracle/Explorer** read and analyse large codebases, returning only high-signal summaries
- **Sisyphus** focuses solely on the files it's modifying — not the entire project architecture
- **Code-Review** examines only changed files — not context from the research phase
- **Atlas** orchestrates without ever touching the bulk of your codebase

What would exhaust 80-90% of a monolithic agent's context now uses 10-15%, leaving the rest for deeper reasoning and faster iterations.

### Typical workflow

```
User → @Prometheus  (plan a feature)
          ├─ @Explorer     (parallel: file discovery)
          └─ @Oracle × N   (parallel: per-subsystem research)
          → writes plan.md → "Start implementation with Atlas" handoff

       @Atlas
          ├─ @Sisyphus  (implement phase 1)  ← parallel for disjoint phases
          ├─ @Code-Review (review phase 1)
          ├─ present commit message → user approval
          └─ repeat for remaining phases
```

### Adding custom agents

The fastest way is to ask Atlas directly:
```
@Atlas Create a new subagent called Security-Auditor that reviews code for vulnerabilities and auth issues. Integrate it with Prometheus and Atlas.
```

Atlas will create the agent file, wire it into Prometheus's research delegation list, and add it to its own subagent roster.

**Manual agent template:**
```yaml
---
description: 'Brief description of what this agent does'
argument-hint: What kind of task to delegate
tools: ['search', 'usages', 'edit', 'runCommands']
model: Claude Sonnet 4.5 (copilot)
---

You are a [ROLE] SUBAGENT called by a parent CONDUCTOR agent.

**Your specialty:** [Domain expertise]
**Your scope:** [What tasks this agent handles]

**Core workflow:**
1. [Step 1]
2. [Step 2]
3. Return structured findings/results to the parent agent
```

---

## Skills

### `mcp-sync`

Bridges the gap between your configured MCP servers and your workspace agent files. When new MCP servers are added to a project, `/mcp-sync` ensures every relevant agent knows about the tools they expose.

**Invoke in Copilot CLI:**
```
/mcp-sync
```

**Or naturally (Copilot auto-detects relevance):**
```
Sync my agents with the available MCP tools
```

**What it does:**

1. **Discover** — Reads `.vscode/mcp.json` (workspace) or user-level MCP config to enumerate configured servers
2. **Introspect** — For each server, runs `mcp-introspect.sh` to list available tools via MCP JSON-RPC `tools/list`
3. **Analyse** — Reads each agent in `.github/agents/` and assesses which tools are relevant based on the agent's role
4. **Update** — For each agent, makes two targeted edits:
   - Adds `mcp/<server>/<tool>` entries to the `tools:` YAML frontmatter
   - Injects/replaces a managed `## MCP Tools Available` block in the agent body
5. **Report** — Prints a structured summary of every change

**Example output:**
```
mcp-sync complete
═══════════════════════════════════════════════════════════════
Servers introspected: github (12 tools), postgres (8 tools)
Servers skipped:      slack (auth required)

Agent updates:
  Atlas.agent.md
    + mcp/github/create_pull_request
    + mcp/github/list_pull_requests
    ✓ ## MCP Tools Available block updated

  Sisyphus-subagent.agent.md
    + mcp/postgres/query
    + mcp/postgres/list_tables
    ✓ ## MCP Tools Available block updated

  Oracle-subagent.agent.md   — no changes (no relevant tools found)
  Explorer-subagent.agent.md — no changes (read-only agent)

Unmapped tools (review manually):
  mcp/github/manage_notifications — not mapped to any agent
```

**Properties:**
- ✅ Idempotent — running twice produces no additional changes
- ✅ Non-destructive — never removes non-MCP tools from agent frontmatter
- ✅ Managed section — only touches the `<!-- mcp-sync:begin -->` / `<!-- mcp-sync:end -->` block

---

### `skill-creator`

A guided workflow for building new skills that integrate with the Atlas agent ecosystem. Whether you want to wrap an existing workflow as a reusable slash command or create a skill from scratch, `/skill-creator` walks you through every step.

**Invoke in Copilot CLI:**
```
/skill-creator
```

**Or naturally (Copilot auto-detects relevance):**
```
Create a new skill for X
Turn this workflow into a skill
Add a skill that does Y
Build a skill for Z
```

**What it does:**

1. **Capture intent** — Understands what the skill should do and when it should trigger, extracting context from the current conversation where possible
2. **Plan structure** — Decides whether helper scripts or reference files are needed alongside `SKILL.md`
3. **Write `SKILL.md`** — Drafts the skill following toolkit conventions (frontmatter, step-by-step instructions, imperative style)
4. **Integrate with agents** — Updates relevant agent files (`Atlas`, `Prometheus`, `Sisyphus`, etc.) with a `## Skills Available` section so agents know when to invoke the skill
5. **Add helper scripts** — Optionally creates POSIX-compatible shell scripts for deterministic operations
6. **Update `README.md`** — Adds the new skill to the directory tree and Skills section

**Properties:**
- ✅ Toolkit-aware — knows the agents, their roles, and how skills wire into the orchestration cycle
- ✅ Checklist-driven — provides a self-review checklist before finishing
- ✅ Flexible — works from a blank slate or from an existing workflow in the conversation

---

## Custom Instructions

The `instructions/copilot-instructions.md` template is installed to:
- Workspace: `.github/copilot-instructions.md`
- User (personal): `~/.copilot/copilot-instructions.md`

Copilot loads this file at the start of every session as persistent guidance. The template covers:

- **General behaviour** — concise, minimal changes, validate before finishing
- **Development workflow** — TDD, agent delegation, plan-before-implement
- **Code style** — match existing conventions, no unnecessary comments
- **Git conventions** — imperative commit messages, `Co-authored-by` trailer, no secrets
- **Agent orchestration** — when to use Atlas vs Prometheus vs direct Copilot

After installing, add project-specific conventions at the bottom of the file.

---

## Hooks

The `hooks/README.md` documents [Copilot CLI hooks](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-hooks) — shell scripts that run at specific lifecycle points in a Copilot CLI session.

| Hook | When it fires |
|------|--------------|
| `sessionStart` / `sessionEnd` | Once per session |
| `userPromptSubmitted` | Each time a prompt is submitted |
| `preToolUse` / `postToolUse` | Before/after any tool runs |
| `errorOccurred` | When an error is raised |
| `agentStop` / `subagentStop` | When main agent or subagent finishes |

Copy-paste examples in `hooks/README.md`:
- **Guardrail**: block `rm -rf` before it runs (`preToolUse`)
- **Transcript archiver**: save session transcripts on end (`sessionEnd`)
- **Retry policy**: auto-retry on rate-limit errors (`errorOccurred`)

---

## Configuration

### VS Code settings

Required for subagent delegation:
```json
{
  "chat.customAgentInSubagent.enabled": true,
  "github.copilot.chat.responsesApiReasoningEffort": "high"
}
```

The installer offers to apply these automatically for workspace installs. For user scope, add them to your User Settings JSON (`Ctrl+Shift+P` → `Open User Settings (JSON)`).

### Plan directory

Agents check for plan directory configuration:
1. Look for `AGENTS.md` in the workspace
2. Find plan directory specification (e.g., `.sisyphus/plans`)
3. Default to `plans/` if not specified

---

## Team sharing (workspace scope)

Commit the `.github/` directory to share the full toolkit with your team:

```bash
git add .github/agents/ .github/skills/ .github/copilot-instructions.md .vscode/settings.json
git commit -m "Add GitHub Copilot Toolkit"
```

Both VS Code Copilot and the Copilot CLI automatically pick up agents and skills from `.github/agents/` and `.github/skills/` in the workspace root.

---

## Requirements

- **VS Code Insiders** (recommended) or VS Code stable
- **GitHub Copilot** subscription with multi-agent support enabled
- **curl** (macOS/Linux) or **PowerShell** (Windows) for installation
- **python3** or **jq** on the PATH (used by `mcp-introspect.sh` to parse MCP responses)

---

## Migration from earlier versions

If you had agents installed from an earlier version of this repo (flat structure, agent files at the repository root), re-run the installer to get the new layout:

```bash
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh \
  | bash -s -- --scope=workspace
```

The installer overwrites existing agent files with the latest versions. Any workspace-level customisations you've made to the agent files will need to be re-applied manually after reinstalling.
