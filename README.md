# llm-wiki-sync

Cross-agent Git sync for your LLM Wiki. Install once, sync knowledge across Claude Code, Codex, OpenCode, Hermes, Cursor, and 46+ agents.

---

## 👤 For Humans

### What is this?

You use multiple AI agents (Claude Code for coding, Hermes for daily tasks, Codex for quick scripts...). Each one learns things. This project makes sure **what one agent learns, all agents know**.

It works through Git:

1. Set up a wiki directory (`~/wiki/`) with a few Markdown files
2. Your agents write knowledge into it
3. This skill auto-commits and pushes to GitHub
4. All other agents pull and read the updates

No servers. No databases. No API costs. Just Git.

### Quick start

```bash
npx skills add HughesCuit/llm-wiki-sync -g -y
bash ~/.agents/skills/llm-wiki-sync/setup.sh --yes
```

The setup script handles everything:
- Creates `~/wiki/` with starter files (if it doesn't exist)
- Initializes Git
- Detects all installed AI agents
- Creates symlinks so every agent can find the sync script
- Guides you through GitHub remote setup

### I don't have a wiki yet

No problem. The setup script creates a starter `~/wiki/wiki.md` for you. Just start writing.

### I use different agents

`setup.sh --yes` auto-detects Claude Code, Codex, OpenCode, Hermes, Cursor, Windsurf, Cline, Continue, Gemini CLI, and Roo Code. If your agent isn't on this list, just create a symlink manually:

```bash
ln -sf ~/.agents/shared/llm-wiki-sync <agent-path>/skills/llm-wiki-sync
```

---

## 🤖 For Agents

### Summary

`llm-wiki-sync` enables multi-agent knowledge sharing via Git. One shared directory (`~/.agents/shared/llm-wiki-sync/`), symlinked from every agent's skill path. Changes are committed and pushed by one agent, pulled by all others.

### Installation

```bash
npx skills add HughesCuit/llm-wiki-sync -g -y
bash ~/.agents/skills/llm-wiki-sync/setup.sh --yes
```

### Structure

```
~/.agents/shared/llm-wiki-sync/
├── SKILL.md                        ← Agent instructions
├── setup.sh                        ← Multi-agent setup + wiki init
├── scripts/sync.sh                 ← Git push/pull/status
└── scripts/integrate-selflearn.txt ← Hermes auto-sync snippet
```

Agent skill symlinks all point to `~/.agents/shared/llm-wiki-sync/`.

### Commands for agents

When user asks to sync wiki knowledge:

```bash
# Push wiki changes to remote
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh push

# Pull latest wiki from remote
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh pull

# Check status
bash ~/.agents/shared/llm-wiki-sync/scripts/sync.sh status
```

### Integration with Claude Code projects

In each coding project's `CLAUDE.md`:

```markdown
## References
- `~/wiki/wiki.md` — project conventions, gotchas, API config
```

### Hermes auto-sync

If Hermes's self-learn hook is active, append `scripts/integrate-selflearn.txt` to `~/.hermes/hooks/self-learn/handler.py`. New knowledge is auto-committed and pushed on every `agent:end` event.

### Architecture

```
[Hermes] learns new knowledge
    ↓ writes to ~/wiki/learnings/
    ↓ self-learn hook: git commit + git push
    ↓
[GitHub] Private repo
    ↑
[Claude Code] git pull → reads updated wiki
[Codex]       git pull → reads updated wiki
[OpenCode]    git pull → reads updated wiki
[Any agent]   git pull → reads updated wiki
```

### Known pitfalls

- Fine-grained GitHub PAT cannot create repos — create manually at github.com/new
- `.gitignore` must exclude `.self-learn-*` temp files
- Symlinks fail across filesystem boundaries (WSL ↔ Windows) — use `--copy` instead
- `git push` in cron/auto-sync needs credential helper or SSH key