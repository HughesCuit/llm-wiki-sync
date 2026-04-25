#!/usr/bin/env bash
# llm-wiki-sync setup — 一键配置多 agent 知识同步
# Usage:
#   bash setup.sh                   交互式安装
#   bash setup.sh --yes             全自动（不询问）
#   bash setup.sh --help            帮助
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$HOME/.agents/shared"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${BOLD}llm-wiki-sync — Multi-Agent Wiki Sync Setup${NC}"
echo "======================================"
echo ""

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------
info()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
code()  { echo ""; echo -e "  ${CYAN}$ ${NC}${BOLD}$1${NC}"; echo "    $2"; echo ""; }
err()   { echo -e "  ${RED}✗${NC} $1"; }

setup_symlink() {
  local agent_name="$1"
  local target_dir="$2"
  local link_path="$target_dir/llm-wiki-sync"

  mkdir -p "$target_dir" 2>/dev/null || true

  if [ -L "$link_path" ]; then
    local current_target
    current_target="$(readlink "$link_path")"
    if [ "$current_target" = "$SHARED_DIR/llm-wiki-sync" ]; then
      info "$agent_name — already configured"
      return 0
    fi
    warn "$agent_name — symlink points elsewhere ($current_target), fixing..."
    rm -f "$link_path"
  fi

  if [ -d "$link_path" ] && [ ! -L "$link_path" ]; then
    warn "$agent_name — existing directory found, backing up..."
    mv "$link_path" "${link_path}.bak.$(date +%s)"
  fi

  ln -sf "$SKILL_DIR" "$link_path"
  info "$agent_name — symlink created ($link_path)"
}

init_wiki() {
  local wiki_dir="$1"

  echo "  Let's create one. This will:"
  echo "    - Create $wiki_dir with a starter wiki.md"
  echo "    - Initialize Git"
  echo "    - Guide you through GitHub remote setup"
  echo ""

  mkdir -p "$wiki_dir"

  cat > "$wiki_dir/wiki.md" << 'WIKI'
# LLM Wiki

Your shared knowledge base for AI agents.

## How to use

- Write project conventions, API configs, gotchas
- Use confidence tags: ✅ verified / 💡 experience / 📋 procedure / ⚠️ speculation
- Git commit after every meaningful change

## Quick start

- **[Project]: ...**
- **[API]: ...**
- **[Gotcha]: ...**
WIKI

  cat > "$wiki_dir/README.md" << 'README'
# LLM Wiki

Shared knowledge base for AI agents (Hermes, Claude Code, Codex, OpenCode, etc.).

Managed with llm-wiki-sync.
README

  cat > "$wiki_dir/.gitignore" << 'GITIGNORE'
# Self-learn temp files
.self-learn-*

# OS
.DS_Store
Thumbs.db

# Editors
.vscode/
.idea/
*.swp
*~
GITIGNORE

  # 确保 Git 有 user config（干净环境可能没有）
  cd "$wiki_dir"
  git init
  git config user.name 2>/dev/null || git config user.name "LLM Wiki"
  git config user.email 2>/dev/null || git config user.email "wiki@localhost"

  git add -A && git commit -m "init" 2>&1 | head -1
  info "Wiki initialized at $wiki_dir"
}

show_usage() {
  cat << 'EOF'
Usage: bash setup.sh [OPTIONS]

Options:
  --yes     Non-interactive mode (auto-install to all detected agents)
  --help    Show this help

What this script does:
  1. Moves skill to ~/.agents/shared/llm-wiki-sync/
  2. Creates symlinks for all detected AI agents
  3. Initializes wiki if needed (with starter template + Git)
  4. Guides you through GitHub remote setup
  5. Tests sync functionality
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
NONINTERACTIVE=false
for arg in "$@"; do
  case "$arg" in
    --yes|-y) NONINTERACTIVE=true ;;
    --help|-h) show_usage ;;
  esac
done

# ---------------------------------------------------------------------------
# Step 1: Ensure shared directory
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 1: Shared directory${NC}"
echo ""

if [ "$SKILL_DIR" != "$SHARED_DIR/llm-wiki-sync" ]; then
  echo "  Moving skill to $SHARED_DIR/llm-wiki-sync ..."
  mkdir -p "$SHARED_DIR"
  cp -r "$SKILL_DIR" "$SHARED_DIR/llm-wiki-sync"
  info "Shared directory ready at $SHARED_DIR/llm-wiki-sync"
  echo "  You can now remove the source: rm -rf $SKILL_DIR"
  SKILL_DIR="$SHARED_DIR/llm-wiki-sync"
else
  info "Already in shared directory: $SKILL_DIR"
fi

echo ""

# ---------------------------------------------------------------------------
# Step 2: Detect and configure agents
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 2: Configure agents${NC}"
echo ""

declare -A AGENTS
AGENTS["Claude Code"]="$HOME/.claude/skills"
AGENTS["Codex"]="$HOME/.codex/skills"
AGENTS["OpenCode"]="$HOME/.config/opencode/skills"
AGENTS["Hermes"]="$HOME/.hermes/skills/note-taking"
AGENTS["Cursor"]="$HOME/.cursor/skills"
AGENTS["Windsurf"]="$HOME/.codeium/windsurf/skills"
AGENTS["Roo Code"]="$HOME/.roo/skills"
AGENTS["Cline"]="$HOME/.agents/skills"
AGENTS["Continue"]="$HOME/.continue/skills"
AGENTS["Gemini CLI"]="$HOME/.gemini/skills"

CONFIGURED=0
SKIPPED=0

for AGENT_NAME in "${!AGENTS[@]}"; do
  AGENT_DIR="${AGENTS[$AGENT_NAME]}"

  if [ ! -d "$(dirname "$AGENT_DIR" 2>/dev/null)" ] && [ ! -d "$AGENT_DIR" ]; then
    continue
  fi

  if $NONINTERACTIVE; then
    setup_symlink "$AGENT_NAME" "$AGENT_DIR"
    CONFIGURED=$((CONFIGURED + 1))
  else
    echo -n "  Configure $AGENT_NAME? [Y/n]: "
    read -r REPLY
    REPLY="${REPLY:-Y}"
    case "$REPLY" in
      [Yy]*)
        setup_symlink "$AGENT_NAME" "$AGENT_DIR"
        CONFIGURED=$((CONFIGURED + 1))
        ;;
      *)
        warn "Skipped $AGENT_NAME"
        SKIPPED=$((SKIPPED + 1))
        ;;
    esac
  fi
done

echo ""
info "$CONFIGURED agent(s) configured, $SKIPPED skipped."
echo ""

# ---------------------------------------------------------------------------
# Step 3: Wiki directory & Git setup
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 3: Wiki directory${NC}"
echo ""

WIKI_DIR="${WIKI_DIR:-$HOME/wiki}"

if [ ! -d "$WIKI_DIR" ]; then
  # Wiki 目录不存在
  warn "Wiki directory ($WIKI_DIR) does not exist."
  if $NONINTERACTIVE; then
    init_wiki "$WIKI_DIR"
  else
    echo -n "  Create it with a starter wiki? [Y/n]: "
    read -r REPLY
    REPLY="${REPLY:-Y}"
    case "$REPLY" in
      [Yy]*) init_wiki "$WIKI_DIR" ;;
      *) warn "Skipped. Create it later: mkdir -p $WIKI_DIR" ;;
    esac
  fi
elif [ ! -d "$WIKI_DIR/.git" ]; then
  # 有目录但没 Git
  warn "Wiki directory exists but is not a Git repository."
  if $NONINTERACTIVE; then
    echo "  Initializing Git..."
    (cd "$WIKI_DIR" && git init && git add -A 2>/dev/null; git commit -m "init" 2>/dev/null || true)
    info "Git initialized in $WIKI_DIR"
  else
    echo -n "  Initialize Git? [Y/n]: "
    read -r REPLY
    REPLY="${REPLY:-Y}"
    case "$REPLY" in
      [Yy]*)
        (cd "$WIKI_DIR" && git init && git add -A 2>/dev/null; git commit -m "init" 2>/dev/null || true)
        info "Git initialized in $WIKI_DIR"
        ;;
      *) warn "Skipped Git init. Run manually: cd $WIKI_DIR && git init" ;;
    esac
  fi
else
  info "Wiki directory exists and is Git-tracked: $WIKI_DIR"
fi

echo ""

# ---------------------------------------------------------------------------
# Step 4: Git remote
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 4: Git remote${NC}"
echo ""

if [ -d "$WIKI_DIR/.git" ]; then
  CURRENT_REMOTE=""
  CURRENT_REMOTE=$(cd "$WIKI_DIR" && git remote get-url origin 2>/dev/null || echo "")
  if [ -n "$CURRENT_REMOTE" ]; then
    info "Remote already configured: $CURRENT_REMOTE"
  else
    warn "No remote configured. Push your wiki to GitHub:"
    echo ""
    echo "    1. Create a new repository at https://github.com/new"
    echo "       (Name it e.g. 'llm-wiki', Private, no README)"
    echo ""
    if ! $NONINTERACTIVE; then
      echo -n "    Enter remote URL (or leave blank to skip): "
      read -r REMOTE_URL
      if [ -n "$REMOTE_URL" ]; then
        local default_branch default_branch=$(cd "$WIKI_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        (cd "$WIKI_DIR" && git remote add origin "$REMOTE_URL" && git push -u origin "$default_branch" 2>/dev/null) && \
          info "Remote configured and pushed!" || \
          warn "Could not push. Check URL and auth."
      fi
    fi
  fi
fi

echo ""

# ---------------------------------------------------------------------------
# Step 5: Verify
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 5: Verification${NC}"
echo ""

echo -n "  "
if bash "$SKILL_DIR/scripts/sync.sh" status 2>&1 | head -6; then
  info "Sync script works!"
else
  warn "Sync check failed — review above."
fi

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "  Next steps:"
echo "    Edit your wiki: $WIKI_DIR/wiki.md"
echo "    Push changes: bash $SKILL_DIR/scripts/sync.sh push"
echo "    Pull on other machines: bash $SKILL_DIR/scripts/sync.sh pull"
echo ""
echo "  Add more agents later:"
echo "    ln -sf $SKILL_DIR <agent-path>/skills/llm-wiki-sync"
echo ""
