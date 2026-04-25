#!/usr/bin/env bash
# wiki-sync — Git 同步脚本（Hermes + Claude Code 通用）
# Usage:
#   ./sync.sh push [--message "提交信息"]
#   ./sync.sh pull
#   ./sync.sh sync    # 先推后拉
#   ./sync.sh status
set -euo pipefail

WIKI_DIR="${WIKI_DIR:-$HOME/wiki}"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-master}"

cd "$WIKI_DIR"

# 检查 Git remote
if ! git remote get-url "$REMOTE" &>/dev/null; then
  echo "ERROR: No remote '$REMOTE' configured. Run:"
  echo "  git remote add origin <your-repo-url>"
  exit 1
fi

case "${1:-status}" in
  push)
    # 检查是否有变更
    if git diff --quiet && git diff --cached --quiet && git ls-files --others --exclude-standard | grep -q . && false; then
      # 有未跟踪文件
      :
    fi
    if git diff --quiet && git diff --cached --quiet; then
      # 再检查未跟踪文件
      if [ -z "$(git ls-files --others --exclude-standard)" ]; then
        echo "✓ 无变更，跳过 push"
        exit 0
      fi
    fi

    # 暂存所有变化
    git add -A
    git add --ignore-errors -A

    # 解析提交信息
    MESSAGE="wiki: auto-sync $(date '+%Y-%m-%d %H:%M')"
    if [ $# -ge 2 ]; then
      case "$2" in
        --message)
          if [ $# -ge 3 ] && [ -n "$3" ]; then
            MESSAGE="$3"
          fi
          ;;
        *)
          MESSAGE="${*:2}"
          ;;
      esac
    fi

    git commit -m "$MESSAGE" 2>/dev/null || { echo "✓ 无新变更"; exit 0; }
    git push "$REMOTE" "$BRANCH" 2>&1 || echo "WARN: push 失败，请检查认证"
    echo "✓ wiki 已同步到远程"
    ;;

  pull)
    git pull --rebase "$REMOTE" "$BRANCH" 2>&1 || {
      echo "ERROR: pull 冲突，已 abort（本地内容未被修改）"
      git rebase --abort 2>/dev/null || true
      exit 1
    }
    echo "✓ wiki 已从远程更新"
    ;;

  sync)
    # 先推后拉，尽可能减少冲突
    $0 push "$@"
    $0 pull
    echo "✓ wiki 双向同步完成"
    ;;

  status)
    echo "=== Wiki Git 状态 ==="
    echo "Remote: $(git remote get-url "$REMOTE" 2>/dev/null || echo '未配置')"
    echo "Branch: $BRANCH"
    echo ""
    git status --short 2>/dev/null | head -20
    echo ""
    echo "最新提交: $(git log --oneline -1 2>/dev/null || echo 'N/A')"
    ;;
esac
