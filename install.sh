#!/usr/bin/env bash
# Install claude-kit into ~/.claude (the user-global Claude Code config).
# Idempotent: re-run it to update. It touches only claude-kit's own files, the
# marked block in ~/.claude/CLAUDE.md, and claude-kit's hook entries in
# ~/.claude/settings.json.
set -euo pipefail
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
kit="$dest/kit"
mkdir -p "$dest/agents" "$dest/skills" "$kit"

# 1. beads CLI
if ! command -v bd >/dev/null 2>&1; then
  npm install -g --silent @beads/bd
fi

# 2. files
rm -rf "$kit/hooks" "$kit/bin" "$kit/templates"
cp -R "$src/claude/hooks" "$src/claude/bin" "$src/templates" "$kit/"
chmod +x "$kit/hooks/"*.py "$kit/bin/"*
cp "$src/claude/agents/"*.md "$dest/agents/"
for s in "$src/claude/skills/"*/; do
  n="$(basename "$s")"; rm -rf "$dest/skills/$n"; cp -R "$s" "$dest/skills/$n"
done

# 3. put kit-init-repo on PATH
bindir=/usr/local/bin
[ -w "$bindir" ] || { bindir="$HOME/.local/bin"; mkdir -p "$bindir"; }
ln -sf "$kit/bin/kit-init-repo" "$bindir/kit-init-repo"

# 4. global CLAUDE.md: replace the marked block, keep everything else
python3 - "$dest/CLAUDE.md" "$src/claude/CLAUDE.md" <<'PY'
import re, sys, os
target, block = sys.argv[1], open(sys.argv[2]).read().strip()
cur = open(target).read() if os.path.exists(target) else ""
pat = re.compile(r"<!-- claude-kit:start.*?<!-- claude-kit:end -->", re.S)
new = pat.sub(lambda _: block, cur) if pat.search(cur) else (cur.rstrip() + "\n\n" + block if cur.strip() else block)
open(target, "w").write(new.rstrip() + "\n")
PY

# 5. hooks in global settings.json (merge; replace earlier claude-kit entries)
python3 - "$dest/settings.json" "$kit" <<'PY'
import json, sys, os
path, kit = sys.argv[1], sys.argv[2]
cfg = json.load(open(path)) if os.path.exists(path) and os.path.getsize(path) else {}
hooks = cfg.setdefault("hooks", {})
want = {
    "SessionStart": f"python3 {kit}/hooks/kit_session_start.py",
    "Stop": f"python3 {kit}/hooks/kit_stop.py",
}
for event, cmd in want.items():
    groups = [g for g in hooks.get(event, [])
              if not any("/kit/hooks/kit_" in h.get("command", "") for h in g.get("hooks", []))]
    groups.append({"matcher": "", "hooks": [{"type": "command", "command": cmd, "timeout": 180}]})
    hooks[event] = groups
json.dump(cfg, open(path, "w"), indent=2)
PY

echo "claude-kit installed into $dest (bd $(bd version 2>/dev/null | awk '{print $3}'))."
