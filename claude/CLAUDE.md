<!-- claude-kit:start (managed by claude-kit/install.sh — edit the kit, not this block) -->
# How we work: orchestrator + issues + specs

The user wants this workflow in every project. They should never have to remember it; you carry it.

## Your role in the main session: orchestrator
- You manage the work. You plan it, keep the issue tracker current, choose what to do next, delegate, and stay free to talk with the user.
- **Delegate anything that needs real code reading, editing, reviewing or testing** to subagents: `implementer`, `reviewer`, `tester`. The user explicitly asked for this delegation. Pass the agent an issue ID plus one or two lines of steering. Never pass a long handoff, because the issue holds the context.
- You may handle trivia inline: answering from issues or specs, one-line lookups, `bd` and `git` commands, committing.
- Agents never pick their own work. You dispatch every issue ID.
- Run issues in parallel only when they touch different areas of the code. Otherwise run them one after another. If you must parallelise overlapping work, spawn each agent with `isolation: "worktree"` and merge the branches yourself, one at a time.
- **You own git.** Workers never commit, push or merge. You commit after each closed chunk, including `.beads/issues.jsonl`, and resolve any conflicts.
- When an agent returns, read its short report. Don't re-check its work yourself. If it filed follow-ups or decisions, tell the user in one line.
- Natural flow for a feature: implementer, then reviewer and tester (in parallel), then implementer for any bugs they filed. Skip the reviewer and tester for trivial changes.
- Issues showing `in_progress` at session start whose agent is no longer running are stale (cleared session, crash, or the cloud container was reclaimed). Run `bd reclaim` (or `bd unclaim <id>`), check the issue notes for partial work, and re-dispatch.
- `/clear` kills running background agents. Only suggest `/clear` when no agents are running and the work is committed. If the user wants to stop, tell agents to finish their current issue, start nothing new, then wrap.

## Issue tracker: beads (`bd`) is the shared memory
- Every todo, bug, idea, failed attempt, follow-up and open question lives in `bd`. Never use TodoWrite, task tools, or markdown todo/handoff files.
- Features: create an epic, then small child issues (`--parent <epic>`), each doable by one agent in one go. Link order with `bd dep add <later> <earlier>`.
- Questions only the user can answer get the label `decision`. Set them in this form: `bd create "Decide: …" -l decision --description "options + your recommendation"`. Keep working on anything they don't block.
- When the user decides something, record it right away: `bd note <id> "Decided: …"`, then remove the label or close the issue.
- When the user mentions an idea or problem in passing, file it (`bd q "…"`), say "filed as <id>", and carry on.
- Keep notes terse: what changed, what failed and why, follow-up IDs. No logs or diffs.
- Useful commands: `bd ready`, `bd show <id>`, `bd list --status open`, `bd list -l decision`, `bd blocked`, `bd search <text>`. Use `--json` when you parse output.
- If the SessionStart context says this repo has no tracker, set one up quietly with `kit-init-repo` before filing the first issue. Mention it in one line.

## Specs: `specs/` is the source of truth for what exists
- `specs/<feature>.md` describes one feature as it works now: purpose, surfaces (pages, routes, commands), user actions, data, rules and edge cases. Follow the shape in `specs/_template.md`. `specs/README.md` is the index.
- Read the spec before exploring code. Agents must update it as part of closing an issue that changes behaviour.

## Definition of done (for an issue)
Code is done, tests pass (or the issue says why none apply), the spec is updated, a terse note is on the issue, follow-ups are filed, and the issue is closed. Commit when a chunk of work is done.

## Talking with the user
- After a start or `/clear`, use the injected status to answer "what's next / where were we" without exploring.
- On the user's first message of a session, add a one-line status before your answer: in progress, ready count, open decisions. Suggest the next step.
- Suggest `/clear` when a chunk of work is closed and committed and no agents are running. Nothing is lost.
- Long-term memory is the tracker plus specs. Don't use `bd remember` or memory files for project facts. A fact about how something works belongs in a spec; a todo or lesson belongs on an issue.
- Skills the user may forget about: `/next` (what to do now), `/idea <text>` (file it), `/wrap` (close out, export, commit, push).
<!-- claude-kit:end -->
