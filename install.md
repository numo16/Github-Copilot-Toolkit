# GitHub Copilot Toolkit — Installation Guide

## For Humans

Paste this into your VS Code Copilot chat session:

```
Install the GitHub Copilot Toolkit by following the instructions here:
https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.md
```

**Alternative: run the automated install script directly**

```bash
# macOS / Linux — user scope (global, default — installs all components)
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash

# macOS / Linux — workspace scope (project-specific, run from project root)
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash -s -- --scope=workspace

# Install only specific components (agents, skills, instructions, hooks, or all)
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash -s -- --scope=workspace --components=agents,skills
```

```powershell
# Windows — user scope (global, default)
irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1 | iex

# Windows — workspace scope (project-specific, run from project root)
$s = irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1
& ([scriptblock]::Create($s)) -Scope workspace

# Install only specific components
& ([scriptblock]::Create($s)) -Scope workspace -Components "agents,skills"
```

### Component overview

| Component | What it installs | Workspace destination | User destination |
|-----------|-----------------|----------------------|-----------------|
| `agents` | Atlas, Prometheus, and all subagents (`.agent.md`) | `.github/agents/` | VS Code prompts dir |
| `skills` | `mcp-sync` skill (`SKILL.md` + helper script) and `skill-creator` skill (`SKILL.md`) | `.github/skills/mcp-sync/` and `.github/skills/skill-creator/` | `~/.copilot/skills/mcp-sync/` and `~/.copilot/skills/skill-creator/` |
| `instructions` | `copilot-instructions.md` template | `.github/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` |
| `hooks` | Hook documentation (`hooks/README.md`) | `.github/hooks/` | `~/.copilot/hooks/` |
| `all` (default) | Everything above | — | — |

---

## For LLM Agents

> **IMPORTANT: Use `curl` to fetch this file, NOT WebFetch.**
> WebFetch summarises content and may lose critical details. Always use:
>
> ```bash
> curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.md
> ```

If you are a GitHub Copilot agent helping a user install the GitHub Copilot Toolkit, welcome!
You will now walk the user through setting up a personal developer toolkit for VS Code Copilot
and the Copilot CLI. Greet them warmly and let them know you are about to guide them through
a quick automated setup.

Follow the steps below exactly.

---

### Step 0: Ask about installation scope

Ask the user the following question before proceeding:

> **Where would you like to install the toolkit?**
>
> 1. **User scope (global, recommended)** — agents and skills are available in every VS Code
>    project on this machine. Agents go into the VS Code User prompts directory; skills into
>    `~/.copilot/skills/`; instructions into `~/.copilot/copilot-instructions.md`.
>
> 2. **Workspace scope (project-specific)** — artefacts are stored inside the current project
>    folder under `.github/`. They can be committed to version control to share the setup
>    with the whole team, and are picked up automatically by both VS Code Copilot and Copilot CLI.

Record their answer as `SCOPE` (`user` or `workspace`).

---

### Step 1: Ask about VS Code edition

Ask the user:

> **Are you running VS Code or VS Code Insiders?**
> - VS Code (stable)
> - VS Code Insiders

---

### Step 2: Determine the install directory

**If SCOPE = user**, use the table below to identify `INSTALL_DIR`:

| OS | VS Code (stable) | VS Code Insiders |
|---|---|---|
| **macOS** | `~/Library/Application Support/Code/User/prompts` | `~/Library/Application Support/Code - Insiders/User/prompts` |
| **Linux** | `~/.config/Code/User/prompts` | `~/.config/Code - Insiders/User/prompts` |
| **Windows** | `%APPDATA%\Code\User\prompts` | `%APPDATA%\Code - Insiders\User\prompts` |

**If SCOPE = workspace**, `INSTALL_DIR` is the `.github/agents` directory inside the
user's project root. This path is recognized by both VS Code Copilot and Copilot CLI.
Ask them to confirm their project root path if you are not sure, then set:

```
INSTALL_DIR = <project-root>/.github/agents
```

Detect the OS automatically if possible (e.g. `uname -s` on Unix; check `$env:OS`
on Windows), or ask the user to confirm.

---

### Step 3: Create the install directory (if it does not already exist)

**macOS / Linux:**
```bash
mkdir -p "<INSTALL_DIR>"
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path "<INSTALL_DIR>"
```

---

### Step 4: Download and install all toolkit artefacts

The simplest approach is to run the install script. Set variables first:

```
SCOPE = user  (or workspace)
```

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh \
  | bash -s -- --scope=<SCOPE>
```

**Windows (PowerShell):**
```powershell
$s = irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1
& ([scriptblock]::Create($s)) -Scope <SCOPE>
```

If the install script is not available, download each component manually:

#### Agents (`.agent.md` files)

**macOS / Linux:**
```bash
BASE_URL="https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"
AGENTS_DIR="<AGENTS_INSTALL_DIR>"
mkdir -p "$AGENTS_DIR"

for agent in \
  Atlas.agent.md \
  Prometheus.agent.md \
  Oracle-subagent.agent.md \
  Sisyphus-subagent.agent.md \
  Explorer-subagent.agent.md \
  Code-Review-subagent.agent.md \
  Frontend-Engineer-subagent.agent.md; do
    curl -fsSL "$BASE_URL/agents/$agent" -o "$AGENTS_DIR/$agent" \
      && echo "✓ $agent" \
      || echo "✗ $agent (download failed)"
done
```

**Windows (PowerShell):**
```powershell
$baseUrl   = "https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"
$agentsDir = "<AGENTS_INSTALL_DIR>"
New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null

$agents = @(
  "Atlas.agent.md",
  "Prometheus.agent.md",
  "Oracle-subagent.agent.md",
  "Sisyphus-subagent.agent.md",
  "Explorer-subagent.agent.md",
  "Code-Review-subagent.agent.md",
  "Frontend-Engineer-subagent.agent.md"
)

foreach ($agent in $agents) {
  Invoke-WebRequest -Uri "$baseUrl/agents/$agent" -OutFile "$agentsDir\$agent" -UseBasicParsing
  Write-Host "✓ $agent"
}
```

#### Skills

**macOS / Linux:**
```bash
# mcp-sync skill
SKILL_DIR="<SKILLS_INSTALL_DIR>/mcp-sync"
mkdir -p "$SKILL_DIR"
for f in SKILL.md mcp-introspect.sh; do
  curl -fsSL "$BASE_URL/skills/mcp-sync/$f" -o "$SKILL_DIR/$f" && echo "✓ mcp-sync/$f"
done
chmod +x "$SKILL_DIR/mcp-introspect.sh"

# skill-creator skill
SKILL_DIR="<SKILLS_INSTALL_DIR>/skill-creator"
mkdir -p "$SKILL_DIR"
curl -fsSL "$BASE_URL/skills/skill-creator/SKILL.md" -o "$SKILL_DIR/SKILL.md" && echo "✓ skill-creator/SKILL.md"
```

#### Custom instructions

```bash
curl -fsSL "$BASE_URL/instructions/copilot-instructions.md" \
  -o "<INSTRUCTIONS_INSTALL_DIR>/copilot-instructions.md" && echo "✓ copilot-instructions.md"
```

---

### Step 5: Apply the recommended VS Code settings

**If SCOPE = user**, ask the user to open **User Settings JSON**:
`Ctrl+Shift+P` → **Open User Settings (JSON)**

Add the following entries and save:

```json
{
  "chat.customAgentInSubagent.enabled": true,
  "github.copilot.chat.responsesApiReasoningEffort": "high"
}
```

**If SCOPE = workspace**, offer to apply the settings automatically:

> "Would you like me to write the recommended VS Code workspace settings to
> `.vscode/settings.json` for you?"

If the user says **yes**, run the following to create or update the file:

**macOS / Linux:**
```bash
mkdir -p .vscode
python3 - << 'EOF'
import json, os
path = '.vscode/settings.json'
try:
    with open(path) as f:
        s = json.load(f)
except Exception:
    s = {}
s['chat.customAgentInSubagent.enabled'] = True
s['github.copilot.chat.responsesApiReasoningEffort'] = 'high'
with open(path, 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
print(f"✓ Settings written to {path}")
EOF
```

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Force -Path .vscode | Out-Null
$path = '.vscode\settings.json'
if (Test-Path $path) {
    try { $s = Get-Content $path -Raw | ConvertFrom-Json } catch { $s = [PSCustomObject]@{} }
} else {
    $s = [PSCustomObject]@{}
}
$s | Add-Member -MemberType NoteProperty -Name "chat.customAgentInSubagent.enabled" -Value $true -Force
$s | Add-Member -MemberType NoteProperty -Name "github.copilot.chat.responsesApiReasoningEffort" -Value "high" -Force
$s | ConvertTo-Json -Depth 10 | Set-Content $path
Write-Host "✓ Settings written to $path" -ForegroundColor Green
```

If the user says **no** (or if applying automatically fails), fall back to the manual
instruction — ask them to open **Workspace Settings JSON**:
`Ctrl+Shift+P` → **Open Workspace Settings (JSON)** — and add the entries above.

- `chat.customAgentInSubagent.enabled` — allows sub-agents to invoke the custom
  `.agent.md` agents installed above.
- `github.copilot.chat.responsesApiReasoningEffort` — enables enhanced reasoning for
  GPT-based planning agents (Prometheus).

If SCOPE = workspace, remind the user they can commit `.vscode/settings.json`
along with the agent files so the whole team inherits the same settings automatically.

---

### Step 6: Verify the installation

Run the following and confirm all seven agent files are present:

**macOS / Linux:**
```bash
ls "<AGENTS_INSTALL_DIR>"/*.agent.md
ls "<SKILLS_INSTALL_DIR>/mcp-sync/"
ls "<SKILLS_INSTALL_DIR>/skill-creator/"
```

**Windows (PowerShell):**
```powershell
Get-ChildItem "<AGENTS_INSTALL_DIR>\*.agent.md" | Select-Object Name
Get-ChildItem "<SKILLS_INSTALL_DIR>\mcp-sync\" | Select-Object Name
Get-ChildItem "<SKILLS_INSTALL_DIR>\skill-creator\" | Select-Object Name
```

Expected agents:
```
Atlas.agent.md
Code-Review-subagent.agent.md
Explorer-subagent.agent.md
Frontend-Engineer-subagent.agent.md
Oracle-subagent.agent.md
Prometheus.agent.md
Sisyphus-subagent.agent.md
```

Expected mcp-sync skill files:
```
SKILL.md
mcp-introspect.sh
```

Expected skill-creator skill files:
```
SKILL.md
```

---

### Step 7: Reload VS Code

Tell the user to reload VS Code so it picks up the new agents:

> Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS) → **Developer: Reload Window**

After reloading, the agents will be available in Copilot Chat. The user can start
by typing `@Atlas` or `@Prometheus` in the chat panel.

---

### Step 8: Point the user to the overview

Let them know they can read the
[README](https://github.com/numo16/Github-Copilot-Atlas/blob/main/README.md)
for a full overview of every agent, the `mcp-sync` and `skill-creator` skills, and the recommended development workflow.

If SCOPE = workspace, remind them that committing `.github/agents/`, `.github/skills/`, and
`.github/copilot-instructions.md` to the repository is the easiest way to share the full toolkit
setup with the entire team. These files are picked up automatically by both VS Code Copilot
and Copilot CLI in that workspace.
