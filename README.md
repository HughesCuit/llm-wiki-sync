# llm-wiki-sync

**Cross-agent Git sync for your LLM Wiki.** Install once, sync knowledge across Claude Code, Codex, OpenCode, Hermes, Cursor, and 46+ agents.

---

## After Install: Run `/llm-wiki-sync init`

```
npx skills add HughesCuit/llm-wiki-sync -g -y
/llm-wiki-sync init          ← interactive setup wizard
```

The `init` wizard:
1. Confirms wiki directory (`~/wiki` default)
2. Asks: **New GitHub repo** / **Existing repo URL** / **Local-only**
3. Creates repo or sets remote URL
4. Explains Fine-grained PAT limitations and workarounds
5. Creates agent symlinks

---

## How It Works

```
[Hermes] learns something new
    ↓ writes to ~/wiki/learnings/
    ↓ self-learn hook: git commit + git push
    ↓
[GitHub] llm-wiki (Private)
    ↑
[Claude Code] git pull → reads updated wiki
[Claude Code] git pull → reads updated wiki
[Any agent]  git pull → reads updated wiki
```

No servers. No databases. No API costs. Just Git.

---

## GitHub PAT Requirements

| Method | Can Create Repo | Can Push |
|-------|----------------|---------|
| gh CLI (logged in) | ✅ Yes | ✅ Yes |
| Classic PAT | ✅ Yes | ✅ Yes |
| Fine-grained PAT | ❌ No | ⚠️ Read-only |

**Fine-grained PAT users**: Create the repo manually at github.com first, then choose "Existing repo" in init.

---

## Commands

| Command | What it does |
|---------|-------------|
| `/llm-wiki-sync init` | Full interactive setup wizard |
| `/llm-wiki-sync sync` | Push wiki changes to GitHub |
| `/llm-wiki-sync pull` | Pull latest from GitHub |

---

## Structure

```
~/.agents/shared/llm-wiki-sync/      ← single source of truth
~/.claude/skills/llm-wiki-sync/      → symlink
~/.codex/skills/llm-wiki-sync/       → symlink
~/.hermes/skills/note-taking/        → symlink
```

---

## Adding a New Agent Later

```bash
ln -sf ~/.agents/shared/llm-wiki-sync ~/.your-agent/skills/llm-wiki-sync
```
