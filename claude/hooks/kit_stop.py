#!/usr/bin/env python3
"""claude-kit Stop hook: keep .beads/issues.jsonl (the git-tracked copy of the
issue database) in sync, so committing the repo always persists the issues.
It is silent and never blocks."""
import json, os, shutil, subprocess, sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:  # noqa: BLE001
    pass


def exe(name):
    """Full path to a command; needed on Windows for npm/bd .cmd shims."""
    return shutil.which(name) or name


def main():
    if not shutil.which("bd"):
        return
    try:
        data = json.load(sys.stdin)
    except Exception:  # noqa: BLE001
        data = {}
    cwd = data.get("cwd") or os.getcwd()
    p = subprocess.run([exe("git"), "-C", cwd, "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    repos = [p.stdout.strip()] if p.returncode == 0 else [
        os.path.join(cwd, d) for d in sorted(os.listdir(cwd)) if os.path.isdir(os.path.join(cwd, d, ".git"))
    ]
    for repo in repos:
        if not os.path.isdir(os.path.join(repo, ".beads")):
            continue
        target = os.path.join(repo, ".beads", "issues.jsonl")
        tmp = target + ".tmp"
        r = subprocess.run([exe("bd"), "export", "-o", tmp], cwd=repo, capture_output=True, timeout=60)
        if r.returncode != 0 or not os.path.exists(tmp):
            continue
        old = open(target, "rb").read() if os.path.exists(target) else None
        new = open(tmp, "rb").read()
        if old == new:
            os.remove(tmp)
        else:
            os.replace(tmp, target)


if __name__ == "__main__":
    try:
        main()
    except Exception:  # noqa: BLE001
        pass
