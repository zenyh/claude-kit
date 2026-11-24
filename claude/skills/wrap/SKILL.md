---
name: wrap
description: Close out a chunk of work. Make sure agents are idle, issues are up to date, export the tracker, commit and push, and say whether it's safe to /clear. Use for /wrap, "wrap up", "let's stop here", "I'm going to bed".
---
1. If any background agents are still running, tell them to finish their current issue and start nothing new, then wait for them.
2. Check that every in-progress issue either has an agent finishing it or a note explaining the state. Close anything that is done.
3. In each repo with `.beads/`, run `bd export -o .beads/issues.jsonl`.
4. Run `git status`, then commit everything, including `.beads/issues.jsonl` and `specs/`, with a message summarising the closed issue IDs. Push if there is a remote. In cloud sessions, pushing is required, or the work is lost when the container is reclaimed.
5. Reply in at most 4 lines: what was closed, what is still open, the commit or branch, and "Safe to /clear."
