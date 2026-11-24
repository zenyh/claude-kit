#!/usr/bin/env bash
# Install claude-kit into ~/.claude (the user-global Claude Code config).
# Works on Linux, macOS and Windows (run it with Git Bash).
# Idempotent: re-run it to update. It touches only claude-kit's own files, the
# marked block in ~/.claude/CLAUDE.md, and claude-kit's hook entries in
# ~/.claude/settings.json.
set -euo pipefail
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
kit="$dest/kit"

# 0. prerequisites
py=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c 'import sys; sys.exit(sys.version_info < (3, 8))' 2>/dev/null; then py="$c"; break; fi
done
[ -n "$py" ] || { echo "claude-kit: Python 3 is required. Windows: winget install Python.Python.3.12 (then reopen the terminal)." >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "claude-kit: git is required." >&2; exit 1; }
if ! command -v bd >/dev/null 2>&1; then
  command -v npm >/dev/null 2>&1 || { echo "claude-kit: Node.js/npm is required to install beads. Windows: winget install OpenJS.NodeJS.LTS (then reopen the terminal)." >&2; exit 1; }
  npm install -g --silent @beads/bd
fi

# Paths written into settings.json must work for Claude Code's hook runner,
# so on Windows use C:/... form instead of Git Bash's /c/... form.
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

# 1. files
mkdir -p "$dest/agents" "$dest/skills" "$kit"
rm -rf "$kit/hooks" "$kit/bin" "$kit/templates"
cp -R "$src/claude/hooks" "$src/claude/bin" "$src/templates" "$kit/"
chmod +x "$kit/hooks/"*.py "$kit/bin/"* 2>/dev/null || true
cp "$src/claude/agents/"*.md "$dest/agents/"
for s in "$src/claude/skills/"*/; do
  n="$(basename "$s")"; rm -rf "$dest/skills/$n"; cp -R "$s" "$dest/skills/$n"
done

# 2. global CLAUDE.md: replace the marked block, keep everything else
"$py" - "$(native "$dest/CLAUDE.md")" "$(native "$src/claude/CLAUDE.md")" <<'PY'
import re, sys, os
target, block = sys.argv[1], open(sys.argv[2], encoding="utf-8").read().strip()
cur = open(target, encoding="utf-8").read() if os.path.exists(target) else ""
pat = re.compile(r"<!-- claude-kit:start.*?<!-- claude-kit:end -->", re.S)
new = pat.sub(lambda _: block, cur) if pat.search(cur) else (cur.rstrip() + "\n\n" + block if cur.strip() else block)
open(target, "w", encoding="utf-8").write(new.rstrip() + "\n")
PY

# 3. hooks in global settings.json (merge; replace earlier claude-kit entries)
pycmd="$py"; [ "$py" = py ] && pycmd="py -3"
"$py" - "$(native "$dest/settings.json")" "$(native "$kit")" "$pycmd" <<'PY'
import json, sys, os
path, kit, py = sys.argv[1], sys.argv[2], sys.argv[3]
cfg = json.load(open(path, encoding="utf-8")) if os.path.exists(path) and os.path.getsize(path) else {}
hooks = cfg.setdefault("hooks", {})
want = {
    "SessionStart": f'{py} "{kit}/hooks/kit_session_start.py"',
    "Stop": f'{py} "{kit}/hooks/kit_stop.py"',
}
for event, cmd in want.items():
    groups = [g for g in hooks.get(event, [])
              if not any("kit/hooks/kit_" in h.get("command", "") for h in g.get("hooks", []))]
    groups.append({"matcher": "", "hooks": [{"type": "command", "command": cmd, "timeout": 180}]})
    hooks[event] = groups
json.dump(cfg, open(path, "w", encoding="utf-8"), indent=2)
PY

echo "claude-kit installed into $dest (bd $(bd version 2>/dev/null | awk '{print $3}'), $py). Start a new Claude Code session to use it."
