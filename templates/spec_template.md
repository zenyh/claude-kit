---
feature: <short-name>
status: live            # live | partial | deprecated
updated: YYYY-MM-DD
issues: [<epic-id>]     # beads epic/issues that built or changed it
code: [path/to/main/module, path/to/other]   # entry points, not every file
---
# <Feature name>

**Purpose:** one or two sentences on what it is for and who uses it.

## Surfaces
Where it shows up: pages and routes, API endpoints, CLI commands, jobs.

## Actions
What a user (or caller) can do, one bullet each: action → result.

## Data
What it reads and writes: tables, fields, files, external APIs.

## Rules & edge cases
Validation, permissions, limits, error states, things that surprised us.

## Not covered / known gaps
Link the beads issues.
