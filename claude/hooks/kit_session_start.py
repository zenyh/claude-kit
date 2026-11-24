#!/usr/bin/env python3
"""claude-kit SessionStart hook.

Runs on startup, resume, /clear and compaction. It makes sure `bd` exists and
restores each repo's issue database from git-tracked JSONL in fresh
containers. It then prints a compact work status, which Claude Code injects
into context. It never fails the session: errors become one line of context.
"""
import json, os, shutil, subprocess, sys

MAX_READY = 8


def run(cmd, cwd=None, timeout=60):
    try:
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout
    except Exception as e:  # noqa: BLE001
        return 1, str(e)


def bd_json(args, cwd):
    code, out = run(["bd", *args, "--json"], cwd=cwd)
    if code != 0:
        return []
    try:
        data = json.loads(out or "[]")
        return data if isinstance(data, list) else []
    except json.JSONDecodeError:
        return []


def ensure_bd():
    if shutil.which("bd"):
        return True
    if shutil.which("npm"):
        run(["npm", "install", "-g", "--silent", "@beads/bd"], timeout=180)
    return bool(shutil.which("bd"))


def git_root(path):
    code, out = run(["git", "-C", path, "rev-parse", "--show-toplevel"], timeout=10)
    return out.strip() if code == 0 else None


def find_repos(cwd):
    root = git_root(cwd)
    if root:
        return [root]
    # Cloud sessions often start one level above the checkouts.
    repos = []
    try:
        for name in sorted(os.listdir(cwd)):
            p = os.path.join(cwd, name)
            if os.path.isdir(os.path.join(p, ".git")):
                repos.append(p)
    except OSError:
        pass
    return repos


def restore_db(repo):
    beads = os.path.join(repo, ".beads")
    run(["git", "-C", repo, "config", "beads.role", "maintainer"], timeout=10)
    try:
        os.chmod(beads, 0o700)
    except OSError:
        pass
    has_db = any(os.path.isdir(os.path.join(beads, d)) for d in ("embeddeddolt", "dolt"))
    if not has_db:
        run(["bd", "bootstrap", "-y"], cwd=repo, timeout=120)


def line(i):
    return f"- {i.get('id')} [P{i.get('priority', '?')}] {i.get('title', '')}"


def status(repo):
    name = os.path.basename(repo)
    out = [f"## Work status: {name}  ({repo})"]
    in_prog = bd_json(["list", "--status", "in_progress"], repo)
    decisions = bd_json(["list", "--status", "open", "-l", "decision"], repo)
    ready = [i for i in bd_json(["ready"], repo) if "decision" not in (i.get("labels") or [])]
    blocked = bd_json(["blocked"], repo)
    open_all = bd_json(["list", "--status", "open"], repo)
    out.append(f"Open: {len(open_all)} | in progress: {len(in_prog)} | ready: {len(ready)} | blocked: {len(blocked)} | decisions waiting on user: {len(decisions)}")
    if in_prog:
        out.append("In progress (may be stale from a previous session; check before re-delegating):")
        out += [line(i) for i in in_prog]
    if decisions:
        out.append("Waiting on the user's decision:")
        out += [line(i) for i in decisions]
    if ready:
        out.append(f"Ready (top {min(len(ready), MAX_READY)}):")
        out += [line(i) for i in ready[:MAX_READY]]
    specs = os.path.join(repo, "specs")
    if os.path.isdir(specs):
        n = len([f for f in os.listdir(specs) if f.endswith(".md") and not f.startswith(("_", "README"))])
        out.append(f"Specs: {n} feature spec(s) in specs/ (index: specs/README.md).")
    else:
        out.append("Specs: none yet. Create specs/ (from the template) when the first feature is documented.")
    return out


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:  # noqa: BLE001
        data = {}
    cwd = data.get("cwd") or os.getcwd()
    lines = ["# claude-kit: orchestrator workflow is active (see ~/.claude/CLAUDE.md)."]
    if not ensure_bd():
        lines.append("WARNING: `bd` (beads) is not installed and auto-install failed. Install with `npm install -g @beads/bd`.")
        print("\n".join(lines))
        return
    repos = find_repos(cwd)
    if not repos:
        lines.append("Not in a git repository: no issue tracker here. Just chat. If the user starts a project, `git init` it and run `kit-init-repo`.")
    for repo in repos:
        if os.path.isdir(os.path.join(repo, ".beads")):
            restore_db(repo)
            lines += status(repo)
        else:
            lines.append(f"## {os.path.basename(repo)} ({repo}): no issue tracker yet. Run `kit-init-repo {repo}` before filing the first issue (no need to ask).")
    print("\n".join(lines))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # noqa: BLE001
        print(f"# claude-kit: status unavailable ({e}). Use `bd ready` manually.")
