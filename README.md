# llm-wiki-sync

Cross-agent Git sync for your LLM Wiki. Install once, sync knowledge across Claude Code, Codex, OpenCode, Hermes, Cursor, and 46+ agents.

## Quick install

```bash
npx skills add HughesCuit/llm-wiki-sync -g -y
bash ~/.agents/skills/llm-wiki-sync/setup.sh --yes
```

## What this does

Every AI agent generates knowledge — project conventions, API gotchas, config tricks, debugging lore. This skill:

1. **Pushes** that knowledge from any agent to a shared Git repo
2. **Pulls** it into all other agents
3. **Auto-syncs** via Hermes self-learn (optional)

No RAG, no vector DB. Just Git.

## File structure

```
~/.agents/shared/llm-wiki-sync/     ← single source of truth
├── SKILL.md                         ← instructions for agents
├── setup.sh                         ← one-command setup (multi-agent symlinks + wiki init)
├── scripts/sync.sh                  ← git push/pull/status
└── scripts/integrate-selflearn.txt  ← Hermes auto-sync snippet

~/.claude/skills/llm-wiki-sync/      → symlink → shared/
~/.codex/skills/llm-wiki-sync/       → symlink → shared/
~/.config/opencode/skills/llm-wiki-sync/ → symlink → shared/
~/.hermes/skills/note-taking/wiki-sync/ → symlink → shared/
```

## User guide (for any agent)

If the user asks "how do I install this?", follow these steps:

### Prerequisites

- Node.js (`node --version`)
- A GitHub account and a private repo (create at github.com/new)
- Git (`git --version`)

### Step-by-step

1. **Install the skill**
   ```bash
   npx skills add HughesCuit/llm-wiki-sync -g -y
   ```

2. **Run the setup script**
   ```bash
   bash ~/.agents/skills/llm-wiki-sync/setup.sh --yes
   ```
   This auto-detects all installed agents, creates symlinks, initializes `~/wiki/` with a starter template, and guides through Git remote setup.

3. **Push your first change**
   ```bash
   bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh push
   ```

4. **Add to a coding project's CLAUDE.md** (or equivalent):
   ```markdown
   ## References
   - `~/wiki/wiki.md` — project conventions, gotchas, API config
   ```

### Commands reference

```bash
bash scripts/sync.sh push              # commit + push changes
bash scripts/sync.sh pull              # pull latest from remote
bash scripts/sync.sh status            # check repo status
```

### New agent later?

```bash
ln -sf ~/.agents/shared/llm-wiki-sync <agent-path>/skills/llm-wiki-sync
```

### Hermes auto-sync

If using Hermes's self-learn hook, append `scripts/integrate-selflearn.txt` to `~/.hermes/hooks/self-learn/handler.py`. New knowledge is then auto-committed and pushed.

## How it works

```
[A] Hermes learns new knowledge
    ↓ writes to ~/wiki/learnings/
    ↓ self-learn hook: git commit + git push
    ↓
[GitHub] Private repo (llm-wiki)
    ↑
[B] Claude Code on another machine: git pull → reads updated wiki
[C] Codex: git pull → reads updated wiki
[D] OpenCode: git pull → reads updated wiki
```

## Design

- Single shared directory (`~/.agents/shared/`), symlinked from every agent's skill path
- One `sync.sh` script, zero daemons, no dependencies beyond `git` and `bash`
- Zero-user-friendly: if `~/wiki/` doesn't exist, setup.sh creates a starter wiki.md with Git initialized
- All data stays on your machines and your GitHub repo — no third-party service
