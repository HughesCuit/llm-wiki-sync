---
name: llm-wiki-sync
description: >
  Cross-agent LLM Wiki Git sync. Install once, sync everywhere.
  Works with 46+ agents: Claude Code, Codex, OpenCode, Cursor, and Hermes.
  Behind the scenes: one shared directory + symlinks per agent.
---

# llm-wiki-sync

Sync your LLM Wiki to a remote Git repository, keeping knowledge shared across
**all your AI agents** — Claude Code, Codex, OpenCode, Hermes, Cursor, and more.

**Not just a SKILL.md.** This package ships `scripts/sync.sh`, a real Git sync
script that stages, commits, and pushes changes. It installs into a shared
`~/.agents/shared/llm-wiki-sync/` directory, then creates symlinks so every
agent can find it.

## When to use

- You use 2+ AI agents (Hermes + Claude Code + Codex + OpenCode + ...)
- You maintain a wiki in Git (`~/wiki/` or similar) and want one agent's
  learning to be instantly available to all others
- You want Hermes's self-learn to auto-commit learned knowledge to GitHub,
  which every other agent can then `git pull`
- You want a single source of truth for project conventions, gotchas, and
  API configs, readable by any agent on any machine

## Installation

### Step 1: Install the skill

```bash
npx skills add HughesCuit/llm-wiki-sync -g -y
```

### Step 2: One-command setup (all agents)

```bash
bash ~/.agents/skills/llm-wiki-sync/setup.sh --yes
```

That's it. The script:

1. Moves the skill to a shared directory (`~/.agents/shared/llm-wiki-sync/`)
2. Detects all installed AI agents (Claude Code, Codex, OpenCode, Hermes, Cursor, etc.)
3. Creates symlinks so every agent finds the same skill from one location
4. Checks your wiki Git remote configuration
5. Verifies the sync script works

#### What if I add a new agent later?

```bash
# Create a symlink for the new agent
ln -sf ~/.agents/shared/llm-wiki-sync ~/.codex/skills/llm-wiki-sync
```

That's it. One script, one update, every agent sees it.

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
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh status
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
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh push

# Push with a descriptive message
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh push --message "Added project guidelines"

# Pull latest from remote
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh pull

# Check status
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh status
```

You can also call via any agent's symlink path — they all resolve to the same script:

```bash
bash ~/.claude/skills/llm-wiki-sync/scripts/sync.sh status    # also works
bash ~/.codex/skills/llm-wiki-sync/scripts/sync.sh status     # also works
```

### Integrating with coding projects

For each project where agents should read wiki content, add to the project's
root config file:

**Claude Code** — `CLAUDE.md`:
```markdown
## References
- `~/wiki/wiki.md` — project conventions, gotchas, API config
```

**Codex** — `AGENTS.md` or `CODEX.md`:
```markdown
## References
- `~/wiki/wiki.md` — project conventions, gotchas, API config
```

**OpenCode** — `OPPENCODE.md` or `.opencode/skills/`:
```markdown
## References
- `~/wiki/wiki.md` — project conventions, gotchas, API config
```

Or create a symlink in any project:
```bash
cd ~/projects/your-project
ln -s ~/wiki ./wiki
```

## How the shared structure works

```
~/.agents/shared/llm-wiki-sync/       ← SINGLE source of truth
├── SKILL.md
├── scripts/sync.sh
└── scripts/integrate-selflearn.txt

~/.claude/skills/llm-wiki-sync/       → symlink → ~/.agents/shared/llm-wiki-sync/
~/.codex/skills/llm-wiki-sync/        → symlink → ~/.agents/shared/llm-wiki-sync/
~/.config/opencode/skills/llm-wiki-sync/ → symlink → ~/.agents/shared/llm-wiki-sync/
~/.hermes/skills/note-taking/wiki-sync/  → symlink → ~/.agents/shared/llm-wiki-sync/
```

Update once, every agent picks it up immediately.

### Hermes self-learn auto-sync

If you use Hermes's self-learn hook, append the code from
`scripts/integrate-selflearn.txt` to `~/.hermes/hooks/self-learn/handler.py`.

After that:

1. ✅ Hermes learns something new → written to `~/wiki/learnings/YYYY-MM-DD.md`
2. ✅ Auto `git commit + git push`
3. ✅ All other agents `git pull` to read the latest knowledge

## The big picture

```
[Hermes] learns something new
    ↓ auto-writes to ~/wiki/learnings/
    ↓ self-learn hook: git commit + git push
    ↓
[GitHub] llm-wiki (Private)
    ↑
[Claude Code] git pull  →  reads updated wiki
[Codex]       git pull  →  reads updated wiki
[OpenCode]    git pull  →  reads updated wiki
[Any agent]   git pull  →  reads updated wiki
```

## Scripts

### `scripts/sync.sh`

| Command | Environment variables | Description |
|---------|---------------------|-------------|
| `push` | `WIKI_DIR` (default: `$HOME/wiki`) | Stage all changes, commit, push |
| `push --message "..."` | | With custom commit message |
| `pull` | `REMOTE` (default: `origin`) | `git pull --rebase` |
| `status` | `BRANCH` (default: `master`) | Show remote, branch, changes |

### `scripts/integrate-selflearn.txt`

Code snippet for Hermes self-learn hook auto-sync.

## Known pitfalls

- **Fine-grained GitHub PAT cannot create repos** — create manually on github.com/new
- **`.gitignore` must exclude temp files** like `.self-learn-*`
- **Symlinks fail across filesystem boundaries** (WSL vs Windows) — use `--copy` instead
- **`git push` in cron/auto-sync needs credential helper** or SSH key
