#!/usr/bin/env bash
# install.sh — GitHub Copilot Toolkit installer for macOS and Linux
#
# Usage (user/global scope — default, installs all components):
#   curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash
#
# Usage (workspace/project scope — run from your project root):
#   curl -fsSL https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main/install.sh | bash -s -- --scope=workspace
#
# Selective install (comma-separated list of: agents, skills, instructions, hooks, all):
#   curl -fsSL ... | bash -s -- --scope=workspace --components=agents,skills
#
# Flags:
#   --scope=user              Install globally into VS Code User prompts / ~/.copilot/
#   --scope=workspace         Install into .github/ in the current directory
#   --components=<list|all>   Which components to install (default: all)

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/numo16/Github-Copilot-Atlas/main"

AGENTS=(
  "Atlas.agent.md"
  "Prometheus.agent.md"
  "Oracle-subagent.agent.md"
  "Sisyphus-subagent.agent.md"
  "Explorer-subagent.agent.md"
  "Code-Review-subagent.agent.md"
  "Frontend-Engineer-subagent.agent.md"
)

# ── Color helpers ─────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}${BOLD}[Toolkit]${RESET} $*"; }
success() { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
error()   { echo -e "${RED}✗${RESET} $*" >&2; }

# ── Parse flags ───────────────────────────────────────────────────────────────
SCOPE="user"
COMPONENTS="all"
for arg in "$@"; do
  case "$arg" in
    --scope=user)        SCOPE="user" ;;
    --scope=workspace)   SCOPE="workspace" ;;
    --components=*)      COMPONENTS="${arg#--components=}" ;;
    *)
      error "Unknown argument: $arg"
      echo "Usage: $0 [--scope=user|workspace] [--components=agents,skills,instructions,hooks,all]" >&2
      exit 1
      ;;
  esac
done

# Normalise COMPONENTS: "all" expands to every component
should_install() {
  local comp="$1"
  [[ "$COMPONENTS" == "all" ]] || echo ",$COMPONENTS," | grep -q ",$comp,"
}

# ── Detect OS ─────────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin) OS_NAME="macOS" ;;
  Linux)  OS_NAME="Linux" ;;
  *)
    error "Unsupported OS: $OS. Please install manually — see install.md."
    exit 1
    ;;
esac

# ── Resolve directories ───────────────────────────────────────────────────────
detect_user_prompts_dir() {
  local stable_dir insiders_dir
  if [[ "$OS_NAME" == "macOS" ]]; then
    stable_dir="$HOME/Library/Application Support/Code/User/prompts"
    insiders_dir="$HOME/Library/Application Support/Code - Insiders/User/prompts"
  else
    stable_dir="$HOME/.config/Code/User/prompts"
    insiders_dir="$HOME/.config/Code - Insiders/User/prompts"
  fi
  if [[ -d "$insiders_dir" ]]; then echo "$insiders_dir"; else echo "$stable_dir"; fi
}

if [[ "$SCOPE" == "workspace" ]]; then
  AGENTS_DIR="$(pwd)/.github/agents"
  SKILLS_DIR="$(pwd)/.github/skills"
  INSTRUCTIONS_DIR="$(pwd)/.github"
  HOOKS_DIR="$(pwd)/.github/hooks"
  SCOPE_LABEL="workspace (.github/)"
else
  AGENTS_DIR="${COPILOT_ATLAS_PROMPTS_DIR:-$(detect_user_prompts_dir)}"
  SKILLS_DIR="$HOME/.copilot/skills"
  INSTRUCTIONS_DIR="$HOME/.copilot"
  HOOKS_DIR="$HOME/.copilot/hooks"
  SCOPE_LABEL="user (global)"
fi

# ── Intro ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║    GitHub Copilot Toolkit — Installer        ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${RESET}"
echo ""
info "Detected OS  : $OS_NAME"
info "Scope        : $SCOPE_LABEL"
info "Components   : $COMPONENTS"
echo ""

FAILED=0

# ── Install agents ────────────────────────────────────────────────────────────
if should_install "agents"; then
  info "Installing agents → $AGENTS_DIR"
  mkdir -p "$AGENTS_DIR"
  for agent in "${AGENTS[@]}"; do
    if curl -fsSL "$BASE_URL/agents/$agent" -o "$AGENTS_DIR/$agent"; then
      success "agents/$agent"
    else
      error "agents/$agent  (download failed)"
      FAILED=1
    fi
  done
  echo ""
fi

# ── Install skills ────────────────────────────────────────────────────────────
install_skill() {
  local skill_name="$1"; shift
  local skill_files=("$@")
  local skill_dest="$SKILLS_DIR/$skill_name"
  info "Installing skill '$skill_name' → $skill_dest"
  mkdir -p "$skill_dest"
  for file in "${skill_files[@]}"; do
    if curl -fsSL "$BASE_URL/skills/$skill_name/$file" -o "$skill_dest/$file"; then
      success "skills/$skill_name/$file"
      [[ "$file" == *.sh ]] && chmod +x "$skill_dest/$file"
    else
      error "skills/$skill_name/$file  (download failed)"
      FAILED=1
    fi
  done
}

if should_install "skills"; then
  install_skill "mcp-sync"      "SKILL.md" "mcp-introspect.sh"
  install_skill "skill-creator" "SKILL.md"
  echo ""
fi

# ── Install instructions ──────────────────────────────────────────────────────
if should_install "instructions"; then
  INSTR_DEST="$INSTRUCTIONS_DIR/copilot-instructions.md"
  info "Installing instructions → $INSTR_DEST"
  mkdir -p "$INSTRUCTIONS_DIR"
  if [[ -f "$INSTR_DEST" ]]; then
    warn "copilot-instructions.md already exists — skipping (edit manually to merge)."
  elif curl -fsSL "$BASE_URL/instructions/copilot-instructions.md" -o "$INSTR_DEST"; then
    success "instructions/copilot-instructions.md"
  else
    error "instructions/copilot-instructions.md  (download failed)"
    FAILED=1
  fi
  echo ""
fi

# ── Install hooks (documentation only for now) ────────────────────────────────
if should_install "hooks"; then
  HOOKS_DEST="$HOOKS_DIR"
  info "Installing hooks documentation → $HOOKS_DEST"
  mkdir -p "$HOOKS_DEST"
  if curl -fsSL "$BASE_URL/hooks/README.md" -o "$HOOKS_DEST/README.md"; then
    success "hooks/README.md"
  else
    error "hooks/README.md  (download failed)"
    FAILED=1
  fi
  echo ""
fi

# ── Result ────────────────────────────────────────────────────────────────────
if [[ "$FAILED" -ne 0 ]]; then
  error "One or more files failed to download. Check your internet connection and try again."
  exit 1
fi

success "Toolkit installed (scope: $SCOPE_LABEL)"
echo ""

if [[ "$SCOPE" == "workspace" ]]; then
  warn "Workspace install — artefacts live in .github/ and are available only in this project."
  echo "  Commit .github/agents/, .github/skills/, .github/copilot-instructions.md to share with your team."
  echo ""
fi

# ── Apply VS Code workspace settings (workspace scope only) ───────────────────
SETTINGS_APPLIED=0
if [[ "$SCOPE" == "workspace" ]] && should_install "agents"; then
  VSCODE_SETTINGS_DIR="$(pwd)/.vscode"
  VSCODE_SETTINGS_FILE="$VSCODE_SETTINGS_DIR/settings.json"

  printf "${CYAN}${BOLD}[Toolkit]${RESET} Apply recommended VS Code workspace settings\n"
  printf "          to ${BOLD}%s${RESET}? [Y/n] " "$VSCODE_SETTINGS_FILE"
  read -r _apply_settings </dev/tty 2>/dev/null || _apply_settings="y"

  if [[ "${_apply_settings,,}" != "n" ]]; then
    mkdir -p "$VSCODE_SETTINGS_DIR"
    _py_tmp=$(mktemp /tmp/atlas_settings_XXXXXX.py)
    cat > "$_py_tmp" << 'PYEOF'
import json, sys
path = sys.argv[1]
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
PYEOF
    if python3 "$_py_tmp" "$VSCODE_SETTINGS_FILE" 2>/dev/null; then
      success "Applied settings to $VSCODE_SETTINGS_FILE"
      SETTINGS_APPLIED=1
    else
      warn "Could not apply settings automatically (python3 not found)."
    fi
    rm -f "$_py_tmp"
  fi
  echo ""
fi

# ── Next steps ────────────────────────────────────────────────────────────────
warn "Next steps:"
STEP=1
if [[ "$SETTINGS_APPLIED" -eq 0 ]] && should_install "agents"; then
  if [[ "$SCOPE" == "user" ]]; then
    echo "  $STEP. Open VS Code User Settings JSON (Ctrl+Shift+P → 'Open User Settings (JSON)')"
    echo "     and add:"
  else
    echo "  $STEP. Open VS Code Workspace Settings JSON (Ctrl+Shift+P → 'Open Workspace Settings (JSON)')"
    echo "     and add:"
  fi
  echo '     {'
  echo '       "chat.customAgentInSubagent.enabled": true,'
  echo '       "github.copilot.chat.responsesApiReasoningEffort": "high"'
  echo '     }'
  STEP=$((STEP + 1))
fi
if should_install "agents"; then
  echo "  $STEP. Reload VS Code (Ctrl+Shift+P → 'Developer: Reload Window')"
  STEP=$((STEP + 1))
  echo "  $STEP. Start chatting with @Atlas or @Prometheus in Copilot Chat!"
  STEP=$((STEP + 1))
fi
if should_install "skills"; then
  echo "  $STEP. Try the built-in skills:"
  echo "         /mcp-sync      — sync agents with MCP tools"
  echo "         /skill-creator — create new custom skills for this toolkit"
  STEP=$((STEP + 1))
fi
echo ""
echo -e "${BOLD}Full documentation:${RESET} https://github.com/numo16/Github-Copilot-Atlas"
echo ""
