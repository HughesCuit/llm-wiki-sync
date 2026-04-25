---
name: llm-wiki-sync
description: >
  Cross-agent LLM Wiki Git sync — one shared knowledge base for all your AI agents.
  Installs once, syncs everywhere (Claude Code, Codex, OpenCode, Hermes, Cursor...).
  After install, type /llm-wiki-sync init to set up your wiki and GitHub repo.
  Ask me to "initialize llm-wiki-sync" or "sync my wiki" to get started.
---

# llm-wiki-sync

## After Installation: Run `/llm-wiki-sync init`

**This skill does NOT set up automatically.** After `npx skills add`, type:

```
/llm-wiki-sync init
```

This starts an interactive setup wizard that:
1. Confirms or creates your wiki directory
2. Asks: New GitHub repo / Existing repo / Local-only
3. Creates the repo or sets the remote URL
4. Handles Fine-grained PAT limitations (can't create repos)
5. Creates agent symlinks

---

## What This Skill Does

Sync your LLM Wiki to a GitHub repository, keeping knowledge shared across **all your AI agents**.

```
[Hermes] learns something new
    ↓ auto-writes to ~/wiki/learnings/
    ↓ self-learn hook: git commit + git push
    ↓
[GitHub] llm-wiki (Private)
    ↑
[Claude Code] git pull  →  reads updated wiki
[Codex]       git pull  →  reads updated wiki
[OpenCode]   git pull  →  reads updated wiki
[Any agent]  git pull  →  reads updated wiki
```

---

## Quick Start

### 1. Install

```bash
npx skills add HughesCuit/llm-wiki-sync -g -y
```

### 2. Initialize (interactive — this sets up wiki + GitHub)

```
/llm-wiki-sync init
```

The init wizard asks:
- Wiki directory (default: `~/wiki`)
- Repo choice: **New GitHub repo** / **Existing repo URL** / **Local-only**
- If Fine-grained PAT detected → explains the limitation and what to do
- Creates agent symlinks automatically

### 3. Done. Next time just ask:

```
/llm-wiki-sync    ← to sync manually
```

Or integrate with self-learn for auto-sync:
- `~/.hermes/hooks/self-learn/` → writes to `~/wiki/learnings/` → auto-commits

---

## init Wizard: What It Handles

| Situation | What init Does |
|-----------|---------------|
| gh CLI logged in | Auto-creates GitHub repo + pushes |
| gh not available | Prompts for classic PAT or manual URL |
| Fine-grained PAT | Explains it can't create repos, suggests workarounds |
| Existing repo | Sets remote URL, tests push |
| Local-only | Skips remote, wiki stays on this machine |

---

## File Structure

```
~/.agents/shared/llm-wiki-sync/   ← single source of truth
├── SKILL.md
├── README.md
├── setup.sh                       ← init + link + sync commands
└── scripts/sync.sh               ← git push/pull/status

~/.claude/skills/llm-wiki-sync/   → symlink → ~/.agents/shared/llm-wiki-sync/
~/.codex/skills/llm-wiki-sync/   → symlink → ~/.agents/shared/llm-wiki-sync/
~/.hermes/skills/note-taking/    → symlink → ~/.agents/shared/llm-wiki-sync/
```

---

## Commands

| Command | What it does |
|---------|-------------|
| `/llm-wiki-sync init` | Full interactive setup wizard |
| `/llm-wiki-sync sync` | Push wiki changes to GitHub |
| `/llm-wiki-sync pull` | Pull latest from GitHub |

---

## GitHub PAT Requirements

| PAT Type | Can Create Repo | Can Push |
|----------|----------------|---------|
| **gh CLI (logged in)** | ✅ Yes | ✅ Yes |
| **Classic PAT** | ✅ Yes | ✅ Yes |
| **Fine-grained PAT** | ❌ No | ⚠️ Read-only (push will fail) |

**Fine-grained PAT users**: Create the repo manually at github.com first, then choose "Existing repo" in init.

---

## GitHub Token Setup (if not using gh CLI)

```bash
# Classic PAT (recommended — full permissions)
gh auth login
# OR set env var:
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Fine-grained PAT (limited — read-only on existing repos)
export GITHUB_TOKEN="github_pat_xxxxxxxxxxxx"
# ⚠️ Cannot create repos. Create at github.com first.
```
