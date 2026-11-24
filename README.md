# claude-kit

A global Claude Code workflow. The main session is a thin **orchestrator** that delegates to agents. A **beads** (`bd`) issue tracker is the shared, long-term memory. **`specs/`** is the source of truth for what exists. You can `/clear` any time without losing anything.

## Install (once per machine; in the cloud, the environment setup script does it)
```bash
git clone <this repo> ~/claude-kit && ~/claude-kit/install.sh
```
It installs `bd` (`npm i -g @beads/bd`) and writes the following into `~/.claude/`: a marked block in `CLAUDE.md`, the agents `implementer`, `reviewer` and `tester`, the skills `/next`, `/idea` and `/wrap`, and SessionStart/Stop hooks in `settings.json`. Re-run it to update. It touches only its own files.

## What happens automatically
- **Session start / `/clear` / resume:** `bd` is installed if missing. A fresh clone's issue database is restored from `.beads/issues.jsonl`. A short status (in progress, decisions waiting on you, ready, blocked) is injected into context.
- **Repo without a tracker:** the orchestrator runs `kit-init-repo` itself, which sets up `.beads/` and `specs/`.
- **Every turn end:** issues are exported to `.beads/issues.jsonl`, so committing the repo saves them.

## What you do
Talk normally. Useful phrases: "what's next?" (`/next`), "add an issue: …" (`/idea`), "wrap up" (`/wrap`, then `/clear`).
Open questions for you are labelled `decision`, and the orchestrator brings them up.

## Layout
`claude/CLAUDE.md` holds the orchestrator rules · `claude/agents/` the worker agents · `claude/skills/` the slash skills · `claude/hooks/` the hooks · `claude/bin/kit-init-repo` the per-repo setup · `templates/` the spec template and index.
