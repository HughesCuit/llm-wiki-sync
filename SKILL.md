---
name: llm-wiki-sync
description: >
  Cross-agent LLM Wiki Git sync. Automatically commit and push wiki changes
  to a remote Git repository so knowledge is shared between Hermes, Claude Code,
  Codex, and other AI agents. Supports push, pull, status, and self-learn auto-sync.
---

# llm-wiki-sync

Sync your LLM Wiki to a remote Git repository, keeping knowledge shared across
AI agents (Hermes, Claude Code, Codex, etc.).

## When to use

- You use multiple AI agents and want them to share the same knowledge base
- You maintain a wiki in Git (`~/wiki/` or similar) and want auto-sync
- You want Hermes's self-learn to auto-commit learned knowledge to GitHub
- You want Claude Code on another machine to `git pull` the latest wiki content

## Installation

### Prerequisites

| Requirement | Check command |
|-------------|---------------|
| Node.js (for npx) | `node --version` |
| Git | `git --version` |
| A wiki directory | `ls ~/wiki/wiki.md` |
| A GitHub repository (private) | Already created at github.com/new |

### Step 1: Install the skill

```bash
npx skills add HughesCuit/llm-wiki-sync -g -a claude-code -y
```

If the agent isn't Claude Code (e.g., you're using Cursor or OpenCode), pass the
correct `--agent` flag or run interactively without flags:

```bash
npx skills add HughesCuit/llm-wiki-sync
```

<details>
<summary>Hermes-specific installation</summary>

Hermes isn't yet in the `npx skills` agent list. Install manually:

```bash
mkdir -p ~/.hermes/skills/note-taking
git clone https://github.com/HughesCuit/llm-wiki-sync.git /tmp/llm-wiki-sync
cp -r /tmp/llm-wiki-sync ~/.hermes/skills/note-taking/wiki-sync
rm -rf /tmp/llm-wiki-sync
```
</details>

### Step 2: Prepare your wiki Git repository

```bash
cd ~/wiki                     # your wiki directory
git init
git add -A
git commit -m "init"

# Connect to your GitHub repository (create one first at github.com/new)
git remote add origin https://github.com/YOUR_USER/YOUR_WIKI_REPO.git
git push -u origin master
```

### Step 3: Verify it works

```bash
bash ~/.claude/skills/llm-wiki-sync/scripts/sync.sh status
```

Expected output:
```
=== Wiki Git Status ===
Remote: https://github.com/.../....
Branch: master

Latest commit: abc1234 init
```

## Usage

### Basic commands

```bash
# Push changes to remote
bash scripts/sync.sh push

# Push with a descriptive message
bash scripts/sync.sh push --message "Added project guidelines"

# Pull latest from remote
bash scripts/sync.sh pull

# Check status
bash scripts/sync.sh status
```

### Setting up auto-sync (cron)

```bash
# Every 6 hours
crontab -e
# Add:
# 0 */6 * * * cd ~/wiki && bash ~/.claude/skills/llm-wiki-sync/scripts/sync.sh push
```

### Integrating with Claude Code projects

For each coding project that should read wiki content:

```bash
cd ~/projects/your-project
echo '## References
- `~/wiki/wiki.md` — project conventions, gotchas, API config' >> CLAUDE.md
```

Or create a symlink so Claude Code can read individual files:

```bash
cd ~/projects/your-project
ln -s ~/wiki ./wiki
```

## How it works

```
[Agent A] learns something new
    ↓ writes to ~/wiki/
    ↓ git commit + git push
    ↓
[GitHub] stores the latest version
    ↑
[Agent B on another machine]
    ↓ git pull
    ↓ reads updated ~/wiki/
```

## Scripts

### `scripts/sync.sh`

| Command | Environment variables | Description |
|---------|---------------------|-------------|
| `push` | `WIKI_DIR` (default: `$HOME/wiki`) | Stage, commit, push |
| `push --message "..."` | | With custom commit message |
| `pull` | `REMOTE` (default: `origin`) | `git pull --rebase` |
| `status` | `BRANCH` (default: `master`) | Show remote/branch/changes |

### `scripts/integrate-selflearn.txt`

Code block for Hermes self-learn hook auto-sync. Copy the content of this file
into `~/.hermes/hooks/self-learn/handler.py` after the `session:end` handler.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `No remote 'origin' configured` | Repository not connected | `git remote add origin <url>` |
| `git push` asks for password | No credential helper | `git config --global credential.helper cache` |
| `npx skills add` not found | Node.js not installed | `curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt install -y nodejs` |
| Permission denied | Wrong remote URL | Check HTTPS vs SSH; use `git remote set-url origin <correct-url>` |

## Known pitfalls

- **Fine-grained GitHub PAT cannot create repos** — always create repos manually on github.com/new
- **`.gitignore` must exclude temp files** like `.self-learn-*` or they show up as untracked every time
- **Symlinks fail across filesystem boundaries** (WSL → Windows) — use `--copy` instead
- **`git push` in cron jobs needs credential helper** or SSH key authentication
