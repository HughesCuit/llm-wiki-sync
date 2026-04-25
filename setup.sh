#!/usr/bin/env bash
# llm-wiki-sync setup — 一键配置多 agent 知识同步架构
# Usage:
#   bash setup.sh                   交互式安装
#   bash setup.sh --yes             全自动安装（不询问）
#   bash setup.sh --help            显示帮助
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$HOME/.agents/shared"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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
    # 旧目录：备份后替换为 symlink
    warn "$agent_name — existing directory found, backing up..."
    mv "$link_path" "${link_path}.bak.$(date +%s)"
  fi

  ln -sf "$SKILL_DIR" "$link_path"
  info "$agent_name — symlink created ($link_path)"
}

show_usage() {
  cat << 'EOF'
Usage: bash setup.sh [OPTIONS]

Options:
  --yes     Non-interactive mode (auto-install to all detected agents)
  --help    Show this help

What this script does:
  1. Creates ~/.agents/shared/llm-wiki-sync/  (or ensures current location)
  2. Sets up symlinks for all detected AI agents
  3. Guides you through wiki Git remote configuration
  4. Tests sync functionality

Supported agents:
  Claude Code, Codex, OpenCode, Hermes, Cursor, Windsurf, and more
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
    # Agent not installed, skip
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
# Step 3: Wiki Git remote
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 3: Wiki Git remote${NC}"
echo ""

WIKI_DIR="${WIKI_DIR:-$HOME/wiki}"

if [ -d "$WIKI_DIR/.git" ]; then
  CURRENT_REMOTE=""
  CURRENT_REMOTE=$(cd "$WIKI_DIR" && git remote get-url origin 2>/dev/null || echo "")
  if [ -n "$CURRENT_REMOTE" ]; then
    info "Wiki Git remote already configured: $CURRENT_REMOTE"
  else
    warn "Wiki is Git-tracked but has no remote."
    if ! $NONINTERACTIVE; then
      echo ""
      echo -n "  Enter remote URL (e.g. https://github.com/YOUR_USER/llm-wiki.git): "
      read -r REMOTE_URL
      if [ -n "$REMOTE_URL" ]; then
        (cd "$WIKI_DIR" && git remote add origin "$REMOTE_URL" && git push -u origin master 2>/dev/null) && \
          info "Remote configured and pushed!" || \
          warn "Could not push. Check URL and auth."
      fi
    fi
  fi
else
  warn "Wiki directory ($WIKI_DIR) is not a Git repository."
  warn "Initialize it: cd $WIKI_DIR && git init && git add -A && git commit -m \"init\""
fi

echo ""

# ---------------------------------------------------------------------------
# Step 4: Verify
# ---------------------------------------------------------------------------
echo -e "${BOLD}Step 4: Verification${NC}"
echo ""

echo -n "  "
if bash "$SKILL_DIR/scripts/sync.sh" status 2>&1 | head -5; then
  info "Sync script works!"
else
  warn "Sync script check failed — review the output above."
fi

echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "  Usage:"
echo "    bash $SKILL_DIR/scripts/sync.sh status         # Check status"
echo "    bash $SKILL_DIR/scripts/sync.sh push           # Push changes"
echo "    bash $SKILL_DIR/scripts/sync.sh pull           # Pull changes"
echo ""
echo "  All configured agents can find this skill under 'llm-wiki-sync'."
echo "  Add new agents: ln -sf $SKILL_DIR <agent-path>/skills/llm-wiki-sync"
