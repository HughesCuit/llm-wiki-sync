---
name: llm-wiki-sync
description: >
  Cross-agent LLM Wiki Git sync. Automatically commit and push wiki changes to
  a remote Git repository so knowledge is shared between Hermes, Claude Code,
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

### From GitHub (any agent)

```bash
npx skills add HughesCuit/llm-wiki-sync -g -a claude-code
```

Or for Hermes, clone to skills directory:

```bash
git clone https://github.com/HughesCuit/llm-wiki-sync.git /tmp/ws
cp -r /tmp/ws ~/.hermes/skills/note-taking/wiki-sync
```

### Pre-requisites

1. A Git-tracked wiki directory (e.g. `~/wiki/`)
2. A remote Git repository (GitHub/GitLab — create manually, fine-grained PATs cannot create repos)
3. Git configured with proper authentication (HTTPS credential helper or SSH)

## Usage

### Basic commands

```bash
# Push changes to remote
bash scripts/sync.sh push --message "Updated project guidelines"

# Pull latest from remote
bash scripts/sync.sh pull

# Check status
bash scripts/sync.sh status
```

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WIKI_DIR` | `$HOME/wiki` | Path to wiki directory |
| `REMOTE` | `origin` | Git remote name |
| `BRANCH` | `master` | Git branch name |

### First-time setup

```bash
cd ~/wiki
git init
git remote add origin https://github.com/YOUR_USER/llm-wiki.git
git add -A && git commit -m "init"
git push -u origin master
```

## Claude Code integration

In each coding project's `CLAUDE.md`:

```markdown
## References
- `~/wiki/wiki.md` — project conventions, gotchas, API config
```

Or create a symlink:

```bash
cd ~/projects/your-project
ln -s ~/wiki ./wiki
```

## Hermes self-learn auto-sync

If you use Hermes's self-learn hook, append this to the end of
`~/.hermes/hooks/self-learn/handler.py` (see `scripts/integrate-selflearn.txt` for
the exact code block). After that, every time Hermes learns something new:

1. ✅ New knowledge written to `~/wiki/learnings/YYYY-MM-DD.md`
2. ✅ Auto `git commit + git push`
3. ✅ Claude Code on other machines can `git pull` to read it

## Scripts

### `scripts/sync.sh`

| Command | Description |
|---------|-------------|
| `push` | Stage all changes, commit, push to remote |
| `pull` | `git pull --rebase` from remote |
| `sync` | Push then pull (bidirectional sync) |
| `status` | Show remote, branch, pending changes |

### `scripts/integrate-selflearn.txt`

Code block to append to `self-learn/handler.py` for auto-sync on knowledge write.

## Known pitfalls

- Fine-grained GitHub PAT cannot create repos — create manually on github.com/new
- `.gitignore` must exclude temp files like `.self-learn-*`
- Symlinks fail across filesystem boundaries (WSL vs Windows)
- `git push` in cron jobs needs credential helper or SSH key
