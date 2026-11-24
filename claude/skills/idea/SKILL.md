---
name: idea
description: Capture an idea, bug, or request into the beads tracker without derailing current work. Use for /idea <text>, or when the user says "add an issue", "note that", "we should also…".
---
1. If this repo has no `.beads/`, run `kit-init-repo` first.
2. Pick the type: bug, feature, or task. A multi-part feature becomes an epic plus 2–6 child issues created with `--parent`, with dependencies set via `bd dep add`.
3. Create it with a one-paragraph description that captures *why*, as the user said it. Use priority 2 unless they signalled urgency.
4. Reply with one line: the "filed as <id>" note plus the title. Don't start working on it unless they asked.
