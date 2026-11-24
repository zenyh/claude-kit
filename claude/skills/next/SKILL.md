---
name: next
description: Tell the user where work stands and what to do next, from the beads tracker. Use when the user asks "what's next", "where were we", "what were you working on", or says /next.
---
Answer from the tracker only. Don't explore code.

1. Run `bd list --status in_progress --json`, `bd list -l decision --status open`, `bd ready`, and `bd list --status closed --sort updated --reverse --limit 5` (recently finished; if those flags aren't supported, use `bd list --status closed --json` and pick the newest).
2. Reply in at most 10 lines:
   - **Recently done**: 1–3 items.
   - **In flight**: in-progress items. Flag any that are stale, meaning no agent is running for them.
   - **Needs you**: open `decision` issues, each with its recommended option.
   - **Next up**: your pick of 1–3 ready issues and why, phrased as a question the user can answer with "go".
3. If the user says go, dispatch agents with the issue IDs.
