#!/usr/bin/env bash
# llm-wiki-sync setup — 多 agent Wiki 知识同步一键配置
#
# Usage:
#   bash setup.sh init                 完整初始化引导（新建或引入仓库）
#   bash setup.sh link-agents          仅创建 agent 符号链接
#   bash setup.sh sync                 仅同步 wiki 到远程
#   bash setup.sh --yes                自动模式（兼容旧用法）
#   bash setup.sh --help               帮助
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="$HOME/.agents/shared"
WIKI_DIR="${WIKI_DIR:-$HOME/wiki}"

# Colors
BOLD='\033[1m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
err()   { echo -e "  ${RED}✗${NC} $1"; }
code()  { echo -e "\n  ${CYAN}$ ${NC}${BOLD}$1${NC}\n"; }
section() { echo -e "\n${BOLD}=== $1 ===${NC}"; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
demand_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

demand_git_config() {
  (cd "$WIKI_DIR" && git config user.name 2>/dev/null) || \
    (cd "$WIKI_DIR" && git config user.name "llm-wiki" && \
     git config user.email "wiki@localhost")
}

init_wiki_files() {
  demand_dir "$WIKI_DIR"
  if [ ! -f "$WIKI_DIR/wiki.md" ]; then
    cat > "$WIKI_DIR/wiki.md" << 'WIKI'
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
  fi
  if [ ! -f "$WIKI_DIR/README.md" ]; then
    cat > "$WIKI_DIR/README.md" << 'R'
# LLM Wiki

Shared knowledge base for AI agents. Managed with llm-wiki-sync.
R
  fi
  if [ ! -f "$WIKI_DIR/.gitignore" ]; then
    cat > "$WIKI_DIR/.gitignore" << 'GITIGNORE'
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
  fi
  if [ ! -d "$WIKI_DIR/.git" ]; then
    demand_git_config
    (cd "$WIKI_DIR" && git init && git add -A && git commit -m "init")
  fi
  info "Wiki ready at $WIKI_DIR"
}

# ---------------------------------------------------------------------------
# PAT type detection
# ---------------------------------------------------------------------------
gh_token_type() {
  local token="$1"
  # gh 检查 token 类型（通过 API）
  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    return 0  # gh 已登录，不需要 token
  fi
  # 简单heuristic：classic PAT 长度 40-，Fine-grained 以 gho_ 开头
  if [[ "$token" == gho_* ]]; then
    echo "fine-grained"
  else
    echo "classic"
  fi
}

# ---------------------------------------------------------------------------
# Step functions
# ---------------------------------------------------------------------------
_step_wiki_dir() {
  section "Step 1: Wiki 目录"
  echo "  默认为: $WIKI_DIR"
  echo -n "  输入自定义路径（或直接回车）: "
  read -r reply
  if [ -n "$reply" ]; then
    WIKI_DIR="$reply"
  fi
  export WIKI_DIR
  init_wiki_files
}

_step_repo_choice() {
  section "Step 2: 仓库状态"
  echo "  [1] 新建 GitHub 仓库（需要 gh CLI 或有创建权限的 PAT）"
  echo "  [2] 我已有仓库，输入 URL"
  echo "  [3] 仅本地 Git，暂不推送到远程"
  echo ""
  echo -n "  选择 [1/2/3，回车默认1]: "
  read -r choice
  choice="${choice:-1}"
  echo "$choice"
}

_step_gh_or_token() {
  # 检测 gh CLI 状态
  if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    echo "gh"
    return
  fi

  # 检查环境变量中的 PAT
  local pat="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [ -n "$pat" ]; then
    local type
    type=$(gh_token_type "$pat")
    if [ "$type" = "fine-grained" ]; then
      echo "fine-grained"
      return
    else
      echo "classic"
      return
    fi
  fi

  echo "none"
}

_gh_create_repo() {
  # 用 gh CLI 创建并 push
  local name="${1:-llm-wiki}"
  if gh repo create "$name" --private --source="$WIKI_DIR" --push 2>&1; then
    info "仓库已创建并推送: https://github.com/$(gh api user --jq .login)/$name"
    return 0
  else
    return 1
  fi
}

_token_create_or_set() {
  # 通过 token 创建（仅 classic PAT 可行）
  local url="$1"
  local branch
  branch=$(cd "$WIKI_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
  (cd "$WIKI_DIR" && git remote add origin "$url" && git push -u origin "$branch") && \
    info "Remote 已设置并推送" && return 0
  return 1
}

_step_new_repo() {
  section "Step 3: 新建 GitHub 仓库"
  local method
  method=$(_step_gh_or_token)
  echo ""

  case "$method" in
    gh)
      info "检测到 gh CLI 已登录"
      echo -n "  仓库名称 [默认: llm-wiki]: "
      read -r repo_name
      repo_name="${repo_name:-llm-wiki}"
      echo "  正在创建仓库..."
      if _gh_create_repo "$repo_name"; then
        return 0
      else
        warn "gh create 失败，尝试手动添加 remote..."
      fi
      ;;
    classic)
      info "检测到 classic PAT"
      warn "Fine-grained PAT 无法创建仓库，请改用 classic PAT 或直接输入已有仓库 URL"
      echo ""
      echo -n "  输入仓库 URL (或直接回车选择选项[2]输入已有URL): "
      read -r url
      if [ -z "$url" ]; then
        _step_existing_repo
        return $?
      fi
      _token_create_or_set "$url"
      return $?
      ;;
    fine-grained)
      warn "检测到 Fine-grained PAT — 此类型无法创建仓库"
      echo ""
      echo "  请选择以下方式之一:"
      echo "    [1] 登录 gh CLI: gh auth login"
      echo "    [2] 使用 classic PAT（需有 repo 创建权限）"
      echo "    [3] 先在 github.com 新建仓库，再选选项[2]输入 URL"
      echo ""
      echo -n "  输入 [1/2/3]: "
      read -r sub_choice
      case "$sub_choice" in
        1) gh auth login && _step_new_repo ;;
        2) echo -n "  输入 classic PAT: "; read -r pat
           export GITHUB_TOKEN="$pat"
           _step_new_repo ;;
        *) warn "跳过远程配置，稍后手动设置" ;;
      esac
      return 0
      ;;
    none)
      warn "未检测到 gh CLI 或 GitHub Token"
      echo ""
      echo "  方式一: 登录 gh CLI（推荐）"
      echo "    gh auth login"
      echo ""
      echo "  方式二: 先在 github.com 新建仓库，再选选项[2]输入 URL"
      echo ""
      echo -n "  回车继续（跳过远程配置）..."
      read -r _
      ;;
  esac
}

_step_existing_repo() {
  section "Step 3: 设置已有仓库"
  echo -n "  粘贴仓库 URL (如 https://github.com/user/repo.git): "
  read -r url
  if [ -z "$url" ]; then
    warn "未输入 URL，跳过"
    return 1
  fi

  local branch
  branch=$(cd "$WIKI_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

  # 检测是否是 Fine-grained PAT（只能拉取）
  local pat="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
  if [ -n "$pat" ] && [[ "$pat" == gho_* ]]; then
    warn "Fine-grained PAT 检测到 — 此类型仅支持拉取，不支持推送"
    echo "  继续设置 remote（push 会失败，需后续更换为 classic PAT）"
  fi

  (cd "$WIKI_DIR" && git remote add origin "$url") 2>/dev/null || \
    (cd "$WIKI_DIR" && git remote set-url origin "$url")

  info "Remote 已设置: $url"
  echo -n "  立即 push 测试？[y/N]: "
  read -r do_push
  if [[ "$do_push" =~ ^[Yy] ]]; then
    (cd "$WIKI_DIR" && git push -u origin "$branch") && \
      info "Push 成功" || warn "Push 失败，请检查 token 权限"
  else
    info "跳过 push，可稍后手动: git -C $WIKI_DIR push -u origin $branch"
  fi
}

_step_summary() {
  section "配置完成"
  echo ""
  echo "  Wiki 目录:    $WIKI_DIR"
  local remote
  remote=$(cd "$WIKI_DIR" && git remote get-url origin 2>/dev/null || echo "未设置")
  echo "  Remote:      $remote"
  echo "  Branch:       $(cd "$WIKI_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  echo ""
  info "所有配置已保存。下次同步："
  echo "  Push: bash $SKILL_DIR/scripts/sync.sh push"
  echo "  Pull: bash $SKILL_DIR/scripts/sync.sh pull"
  echo "  状态: bash $SKILL_DIR/scripts/sync.sh status"
}

# ---------------------------------------------------------------------------
# Agent symlinks
# ---------------------------------------------------------------------------
link_agents() {
  section "创建 Agent 符号链接"

  demand_dir "$SHARED_DIR"

  # Move to shared if not already there
  if [ "$SKILL_DIR" != "$SHARED_DIR/llm-wiki-sync" ]; then
    echo "  移动到共享目录..."
    mkdir -p "$SHARED_DIR"
    cp -r "$SKILL_DIR" "$SHARED_DIR/llm-wiki-sync"
    SKILL_DIR="$SHARED_DIR/llm-wiki-sync"
    info "已复制到 $SKILL_DIR"
  fi

  declare -A AGENTS=(
    ["Claude Code"]="$HOME/.claude/skills"
    ["Codex"]="$HOME/.codex/skills"
    ["OpenCode"]="$HOME/.config/opencode/skills"
    ["Hermes"]="$HOME/.hermes/skills/note-taking"
    ["Cursor"]="$HOME/.cursor/skills"
    ["Windsurf"]="$HOME/.codeium/windsurf/skills"
    ["Roo Code"]="$HOME/.roo/skills"
    ["Cline"]="$HOME/.agents/skills"
    ["Continue"]="$HOME/.continue/skills"
    ["Gemini CLI"]="$HOME/.gemini/skills"
  )

  local configured=0
  for name in "${!AGENTS[@]}"; do
    local dir="${AGENTS[$name]}"
    mkdir -p "$(dirname "$dir")" 2>/dev/null || true
    if [ -d "$dir" ] || [ -d "$(dirname "$dir")" ]; then
      local link="$dir/llm-wiki-sync"
      if [ -L "$link" ]; then
        local target
        target=$(readlink "$link")
        if [ "$target" = "$SKILL_DIR" ]; then
          info "$name — 已链接"
          continue
        fi
        rm "$link"
      elif [ -d "$link" ]; then
        mv "$link" "${link}.bak.$(date +%s)"
      fi
      ln -sf "$SKILL_DIR" "$link"
      info "$name — 链接已创建"
      configured=$((configured + 1))
    fi
  done
  echo ""
  info "$configured 个 agent 已链接"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
cmd_init() {
  echo ""
  echo -e "${BOLD}llm-wiki-sync 初始化向导${NC}"
  echo "========================================"
  echo ""

  _step_wiki_dir
  echo ""

  local choice
  choice=$(_step_repo_choice)
  echo ""

  case "$choice" in
    1) _step_new_repo ;;
    2) _step_existing_repo ;;
    3) warn "跳过远程配置，wiki 仅本地 Git 管理" ;;
    *) warn "无效选择" ;;
  esac

  _step_summary
}

cmd_sync() {
  bash "$SKILL_DIR/scripts/sync.sh" "${@:-status}"
}

cmd_help() {
  cat << 'EOF'
llm-wiki-sync setup

Commands:
  init             完整初始化向导（新建/引入仓库 + 链接 agents）
  link-agents      仅创建 agent 符号链接
  sync [args]      运行 sync.sh（等同于 bash scripts/sync.sh）
  --yes            自动模式（不询问，后向兼容）

Examples:
  bash setup.sh init
  bash setup.sh init --wiki-dir /path/to/wiki
  bash setup.sh link-agents
  bash setup.sh sync push
  bash setup.sh sync pull
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
case "${1:-}" in
  init)
    shift
    # 支持 --wiki-dir 参数
    for arg in "$@"; do
      case "$arg" in
        --wiki-dir) ;;
        --wiki-dir=*) WIKI_DIR="${arg#*=}" ;;
      esac
    done
    cmd_init
    ;;
  link-agents) link_agents ;;
  sync)        shift; cmd_sync "$@" ;;
  --yes|auto)
    # 后向兼容：用默认选项静默初始化
    echo -e "${BOLD}Auto mode (--yes)${NC} — using defaults"
    echo "  Tip: run 'bash setup.sh init' for interactive setup"
    WIKI_DIR="${WIKI_DIR:-$HOME/wiki}"
    init_wiki_files
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
      echo "  Detected gh CLI — attempting auto-repo-create..."
      if ! _gh_create_repo "llm-wiki" 2>/dev/null; then
        warn "Could not auto-create repo. Run 'bash setup.sh init' to configure manually."
      fi
    else
      warn "No gh CLI — remote not configured. Run 'bash setup.sh init' for guidance."
    fi
    link_agents
    _step_summary
    ;;
  --help|-h)   cmd_help ;;
  "")           cmd_help ;;
esac
