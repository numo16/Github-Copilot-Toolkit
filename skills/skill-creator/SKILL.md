---
name: skill-creator
description: >
  Creates new skills for the GitHub Copilot Atlas toolkit. Use this when you want to
  build a new /skill-name skill from scratch, wrap an existing workflow as a reusable
  skill, or add a skill that integrates with the Atlas, Prometheus, Sisyphus, or other
  agents in this toolkit. Invoke with /skill-creator, or ask Copilot to "create a new
  skill", "add a skill", "build a skill for X", or "turn this workflow into a skill".
---

A skill for creating new skills in the GitHub Copilot Atlas toolkit and wiring them into the existing agent ecosystem.

## What this skill does

Guides you through the full lifecycle of adding a new skill:

1. **Capture intent** — understand what the skill should do and when it should trigger
2. **Plan the structure** — decide whether helper scripts or reference files are needed
3. **Write `SKILL.md`** — draft the skill instructions following toolkit conventions
4. **Integrate with agents** — update relevant agent files so they are aware of the skill
5. **Add helper scripts** — optionally add shell scripts or reference documents
6. **Update documentation** — add the skill to `README.md`
7. **Self-review** — verify the skill against a checklist before finishing

---

## Step 1 — Capture Intent

Start by understanding the user's goal. If the current conversation already describes a workflow the user wants to capture (e.g., "turn this into a skill"), extract the intent from that history first — the steps taken, corrections made, and outputs produced. Only ask for what is missing.

Otherwise, ask:

1. What should the skill enable Copilot to do?
2. When should it trigger? (what user phrases or contexts)
3. Does it need helper scripts or reference files?
4. Which agents in the toolkit should know about it (Atlas, Prometheus, Sisyphus, Oracle, Explorer, Code-Review, Frontend-Engineer), if any?

Confirm your understanding before proceeding.

---

## Step 2 — Plan the Skill Structure

Choose a structure based on the skill's complexity:

**Simple skill** (instructions only):
```
skills/<skill-name>/
└── SKILL.md
```

**Skill with helpers:**
```
skills/<skill-name>/
├── SKILL.md
├── <helper>.sh           (POSIX-compatible shell script)
└── references/
    └── <reference>.md    (large reference documents)
```

Keep `SKILL.md` under ~500 lines. If instructions grow large, move reference material into a `references/` subdirectory and link to those files clearly from `SKILL.md`.

---

## Step 3 — Write SKILL.md

Create `skills/<skill-name>/SKILL.md` using the structure below.

### YAML frontmatter

```yaml
---
name: <skill-name>
description: >
  <One-paragraph description. Start with what the skill does, then list specific
  contexts and phrases that should trigger it. Be explicit — Copilot tends to
  under-trigger skills, so include all realistic phrasings. Example: "Use this
  when the user asks to X, wants to Y, or says 'do Z'.">
---
```

### Body template

```markdown
<One-line summary of the skill's purpose.>

## Goal

<State the skill's objective in 2–4 sentences.>

---

## Step 1 — <First major action>

<Detailed instructions. Use imperative form: "Read ...", "Parse ...", "Update ...">

---

## Step 2 — <Second major action>

<Detailed instructions.>

---

## Rules

- <Rule 1>
- <Rule 2>
```

### Description field guidelines

The `description` field is the primary mechanism by which Copilot decides whether to invoke this skill. It must:

- State **what** the skill does in the first sentence
- List **when** to use it, with specific invocation contexts and phrases
- Be "pushy" — mention every likely phrasing to prevent under-triggering

**Example (good):**
```
Synchronizes MCP server tools with workspace-scoped custom agent files.
Use this when MCP servers have been added or changed in the project and you
want the workspace agent files in .github/agents/ to reflect the newly
available tools. Invoke with /mcp-sync, or ask Copilot to "sync my agents
with MCP tools".
```

### Writing style

- Use imperative mood for instructions: "Read …", "Parse …", "Update …"
- Explain *why* a step matters, not just *what* to do
- Include worked examples where a format or output is not obvious
- Prefer bullet lists and tables over dense prose

---

## Step 4 — Integrate with Agents

Decide which agents should know about the new skill. Agent files are located at:
- **Workspace scope**: `.github/agents/` in the project root
- **User scope**: the VS Code User prompts directory (`~/Library/Application Support/Code - Insiders/User/prompts` on macOS, `~/.config/Code - Insiders/User/prompts` on Linux, `%APPDATA%\Code - Insiders\User\prompts` on Windows; replace "Insiders" with "Code" for stable)

Refer to this table to decide which agents to update:

| Agent | Integrate when… |
|-------|----------------|
| **Atlas** | The skill can be invoked as part of the orchestration lifecycle (e.g., a deployment or packaging skill Atlas can delegate) |
| **Prometheus** | The skill supports the planning phase (e.g., a research or requirements-gathering skill) |
| **Sisyphus** | The skill supports implementation (e.g., a code-generation or scaffolding skill) |
| **Oracle** | The skill provides deep research or documentation lookup capabilities |
| **Explorer** | The skill supports read-only codebase analysis |
| **Code-Review** | The skill assists with review workflows (e.g., a security scan or lint skill) |
| **Frontend-Engineer** | The skill is relevant to UI/UX work (e.g., a component generator or a11y checker) |

### How to update an agent file

Add a `## Skills Available` section to the agent's body (create it if absent), just before the first `<workflow>` tag or at the end of the file. List the new skill and when the agent should invoke it:

```markdown
## Skills Available

### `/<skill-name>`
<One sentence: what the skill does and when this agent should invoke it.>
```

Do **not** add the skill to the agent's `tools:` YAML frontmatter — skills are invoked by slash command (`/<skill-name>`), not by tool ID.

---

## Step 5 — Add Helper Scripts (Optional)

If the skill needs to run deterministic or repetitive operations, add a shell script:

1. Place it alongside `SKILL.md` in `skills/<skill-name>/`
2. Make it POSIX-compatible — use `#!/usr/bin/env bash` and avoid GNU-only extensions
3. Include a usage comment block at the top:

```bash
#!/usr/bin/env bash
# <script-name>.sh — <one-line description>
#
# Usage:
#   bash <script-name>.sh <arg1> [arg2 ...]
#
# Exit codes:
#   0 — success
#   1 — error
```

4. Reference the script from `SKILL.md` with the exact invocation, using the scope-appropriate path:
   - **Workspace scope**: `bash .github/skills/<skill-name>/<script-name>.sh <args>`
   - **User scope**: `bash ~/.copilot/skills/<skill-name>/<script-name>.sh <args>`

---

## Step 6 — Update README.md

Add the new skill to the repository's `README.md` in two places:

### 1. Directory tree (under `## What's in the toolkit`)

Add a row beneath `mcp-sync`:
```
│   ├── <skill-name>/                # Agent Skill: <brief description>
│   │   └── SKILL.md                 # Skill instructions
```

If the skill has helper scripts or references, list those files too.

### 2. Skills section (under `## Skills`)

Add a `### \`<skill-name>\`` subsection describing:

- What the skill does
- How to invoke it (`/<skill-name>` and any natural-language triggers)
- What it does step by step (numbered list or bullet points)
- Key properties (idempotent, non-destructive, requires X, etc.)

---

## Step 7 — Self-Review Checklist

Before finishing, verify each item:

- [ ] `skills/<skill-name>/SKILL.md` exists and has valid YAML frontmatter (`name` and `description` present)
- [ ] `description` clearly explains when to trigger the skill and covers all likely phrasings
- [ ] Steps are ordered, actionable, and use imperative mood
- [ ] Helper scripts (if any) are POSIX-compatible and have a usage comment at the top
- [ ] Relevant agent files have been updated with a `## Skills Available` section (if applicable)
- [ ] `README.md` directory tree and Skills section are updated

---

## Rules

- **`SKILL.md` is the only required file.** Helper scripts and references are optional.
- **Keep `SKILL.md` focused.** Move reference material to `references/` if it would push the file past ~500 lines.
- **POSIX scripts only.** Shell scripts must work on macOS and Linux without GNU-specific extensions.
- **No secrets.** Never include API keys, tokens, or hardcoded credentials in skill files.
- **Idempotent where possible.** Skills that modify files should produce no additional changes when run a second time.
- **Respect agent boundaries.** Don't add an edit-capable skill to a read-only agent (e.g., Explorer), and don't add research tools to an implementation-only agent (e.g., Sisyphus).
