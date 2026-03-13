# install.ps1 — GitHub Copilot Toolkit installer for Windows (PowerShell)
#
# Usage (user/global scope — default, installs all components):
#   irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1 | iex
#
# Usage (workspace/project scope — run from your project root):
#   $s = irm https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.ps1
#   & ([scriptblock]::Create($s)) -Scope workspace
#
# Selective install (comma-separated list of: agents, skills, instructions, hooks, all):
#   & ([scriptblock]::Create($s)) -Scope workspace -Components "agents,skills"
#
# Parameters:
#   -Scope user              Install globally into VS Code User prompts / ~/.copilot/
#   -Scope workspace         Install into .github/ in the current directory
#   -Components <list|all>   Which components to install (default: all)

param(
  [ValidateSet("user", "workspace")]
  [string]$Scope = "user",

  [string]$Components = "all"
)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"

$Agents = @(
  "Atlas.agent.md",
  "Prometheus.agent.md",
  "Oracle-subagent.agent.md",
  "Sisyphus-subagent.agent.md",
  "Explorer-subagent.agent.md",
  "Code-Review-subagent.agent.md",
  "Frontend-Engineer-subagent.agent.md"
)

$SkillName  = "mcp-sync"
$SkillFiles = @("SKILL.md", "mcp-introspect.sh")

# ── Helper: check if a component is selected ──────────────────────────────────
function Should-Install([string]$comp) {
  return ($Components -eq "all") -or ($Components -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -eq $comp })
}

# ── Detect VS Code edition ─────────────────────────────────────────────────────
function Get-UserPromptsDir {
  $stableDir   = Join-Path $env:APPDATA "Code\User\prompts"
  $insidersDir = Join-Path $env:APPDATA "Code - Insiders\User\prompts"
  if (Test-Path $insidersDir) { return $insidersDir }
  return $stableDir
}

# ── Resolve directories ────────────────────────────────────────────────────────
if ($Scope -eq "workspace") {
  $AgentsDir       = Join-Path (Get-Location) ".github\agents"
  $SkillsDir       = Join-Path (Get-Location) ".github\skills"
  $InstructionsDir = Join-Path (Get-Location) ".github"
  $HooksDir        = Join-Path (Get-Location) ".github\hooks"
  $ScopeLabel      = "workspace (.github\)"
} else {
  $AgentsDir       = if ($env:COPILOT_ATLAS_PROMPTS_DIR) { $env:COPILOT_ATLAS_PROMPTS_DIR } else { Get-UserPromptsDir }
  $SkillsDir       = Join-Path $HOME ".copilot\skills"
  $InstructionsDir = Join-Path $HOME ".copilot"
  $HooksDir        = Join-Path $HOME ".copilot\hooks"
  $ScopeLabel      = "user (global)"
}

# ── Intro ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    GitHub Copilot Toolkit — Installer        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "[Toolkit] Scope      : $ScopeLabel" -ForegroundColor Cyan
Write-Host "[Toolkit] Components : $Components" -ForegroundColor Cyan
Write-Host ""

$Failed = 0

# ── Install agents ─────────────────────────────────────────────────────────────
if (Should-Install "agents") {
  Write-Host "[Toolkit] Installing agents → $AgentsDir" -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
  foreach ($agent in $Agents) {
    $url  = "$BaseUrl/agents/$agent"
    $dest = Join-Path $AgentsDir $agent
    try {
      Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
      Write-Host "  ✓ agents/$agent" -ForegroundColor Green
    } catch {
      Write-Host "  ✗ agents/$agent  (download failed: $_)" -ForegroundColor Red
      $Failed++
    }
  }
  Write-Host ""
}

# ── Install skills ─────────────────────────────────────────────────────────────
if (Should-Install "skills") {
  $SkillDest = Join-Path $SkillsDir $SkillName
  Write-Host "[Toolkit] Installing skill '$SkillName' → $SkillDest" -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $SkillDest | Out-Null
  foreach ($file in $SkillFiles) {
    $url  = "$BaseUrl/skills/$SkillName/$file"
    $dest = Join-Path $SkillDest $file
    try {
      Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
      Write-Host "  ✓ skills/$SkillName/$file" -ForegroundColor Green
    } catch {
      Write-Host "  ✗ skills/$SkillName/$file  (download failed: $_)" -ForegroundColor Red
      $Failed++
    }
  }
  Write-Host ""
}

# ── Install instructions ───────────────────────────────────────────────────────
if (Should-Install "instructions") {
  $InstrDest = Join-Path $InstructionsDir "copilot-instructions.md"
  Write-Host "[Toolkit] Installing instructions → $InstrDest" -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $InstructionsDir | Out-Null
  if (Test-Path $InstrDest) {
    Write-Host "  ⚠ copilot-instructions.md already exists — skipping (edit manually to merge)." -ForegroundColor Yellow
  } else {
    try {
      Invoke-WebRequest -Uri "$BaseUrl/instructions/copilot-instructions.md" -OutFile $InstrDest -UseBasicParsing
      Write-Host "  ✓ instructions/copilot-instructions.md" -ForegroundColor Green
    } catch {
      Write-Host "  ✗ instructions/copilot-instructions.md  (download failed: $_)" -ForegroundColor Red
      $Failed++
    }
  }
  Write-Host ""
}

# ── Install hooks (documentation only) ────────────────────────────────────────
if (Should-Install "hooks") {
  Write-Host "[Toolkit] Installing hooks documentation → $HooksDir" -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null
  try {
    Invoke-WebRequest -Uri "$BaseUrl/hooks/README.md" -OutFile (Join-Path $HooksDir "README.md") -UseBasicParsing
    Write-Host "  ✓ hooks/README.md" -ForegroundColor Green
  } catch {
    Write-Host "  ✗ hooks/README.md  (download failed: $_)" -ForegroundColor Red
    $Failed++
  }
  Write-Host ""
}

# ── Result ─────────────────────────────────────────────────────────────────────
if ($Failed -gt 0) {
  Write-Host "✗ $Failed file(s) failed to download. Check your internet connection and try again." -ForegroundColor Red
  exit 1
}

Write-Host "✓ Toolkit installed (scope: $ScopeLabel)" -ForegroundColor Green
Write-Host ""

if ($Scope -eq "workspace") {
  Write-Host "⚠ Workspace install — artefacts live in .github\ and are available only in this project." -ForegroundColor Yellow
  Write-Host "  Commit .github\agents\, .github\skills\, .github\copilot-instructions.md to share with your team."
  Write-Host ""
}

# ── Apply VS Code workspace settings (workspace scope, agents installed) ───────
$SettingsApplied = $false
if ($Scope -eq "workspace" -and (Should-Install "agents")) {
  $VsCodeDir    = Join-Path (Get-Location) ".vscode"
  $SettingsFile = Join-Path $VsCodeDir "settings.json"

  $applySettings = Read-Host "[Toolkit] Apply recommended VS Code workspace settings to '$SettingsFile'? [Y/n]"

  if ($applySettings -notmatch '^[Nn]') {
    New-Item -ItemType Directory -Force -Path $VsCodeDir | Out-Null
    if (Test-Path $SettingsFile) {
      try { $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json } catch { $settings = [PSCustomObject]@{} }
    } else {
      $settings = [PSCustomObject]@{}
    }
    $settings | Add-Member -MemberType NoteProperty -Name "chat.customAgentInSubagent.enabled"                -Value $true  -Force
    $settings | Add-Member -MemberType NoteProperty -Name "github.copilot.chat.responsesApiReasoningEffort"  -Value "high" -Force
    $settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile
    Write-Host "✓ Applied settings to $SettingsFile" -ForegroundColor Green
    $SettingsApplied = $true
  }
  Write-Host ""
}

# ── Next steps ─────────────────────────────────────────────────────────────────
Write-Host "Next steps:" -ForegroundColor Yellow
$step = 1
if (-not $SettingsApplied -and (Should-Install "agents")) {
  if ($Scope -eq "user") {
    Write-Host "  $step. Open VS Code User Settings JSON (Ctrl+Shift+P → 'Open User Settings (JSON)')"
  } else {
    Write-Host "  $step. Open VS Code Workspace Settings JSON (Ctrl+Shift+P → 'Open Workspace Settings (JSON)')"
  }
  Write-Host "     and add:"
  Write-Host '     {'
  Write-Host '       "chat.customAgentInSubagent.enabled": true,'
  Write-Host '       "github.copilot.chat.responsesApiReasoningEffort": "high"'
  Write-Host '     }'
  $step++
}
if (Should-Install "agents") {
  Write-Host "  $step. Reload VS Code (Ctrl+Shift+P → 'Developer: Reload Window')"
  $step++
  Write-Host "  $step. Start chatting with @Atlas or @Prometheus in Copilot Chat!"
  $step++
}
if (Should-Install "skills") {
  Write-Host "  $step. Use the mcp-sync skill: run /mcp-sync in the Copilot CLI, or ask Copilot to sync your agents with MCP tools."
  $step++
}
Write-Host ""
Write-Host "Full documentation: https://github.com/numo16/Github-Copilot-Atlas" -ForegroundColor Cyan
Write-Host ""
