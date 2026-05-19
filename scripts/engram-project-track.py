#!/usr/bin/env python3
"""
PostToolUse hook: tracks active engram project based on file path being edited/read.
Only injects context when project changes (mid-session switch detection).
Source of truth: ~/.claude/engram-sync-config.json
State file:      ~/.claude/engram-active-project.tmp
"""
import json, os, sys


def find_git_root(path):
    current = os.path.abspath(path if os.path.isdir(path) else os.path.dirname(path))
    while True:
        if os.path.exists(os.path.join(current, '.git')):
            return current
        parent = os.path.dirname(current)
        if parent == current:
            return None
        current = parent


try:
    data = json.load(sys.stdin)
    file_path = data.get('tool_input', {}).get('file_path', '')
    if not file_path:
        exit(0)

    config_path = os.path.expanduser('~/.claude/engram-sync-config.json')
    with open(config_path) as f:
        known_projects = json.load(f).get('projects', [])

    git_root = find_git_root(file_path)
    if not git_root:
        exit(0)

    project = os.path.basename(git_root)
    if project not in known_projects:
        exit(0)

    state_file = os.path.expanduser('~/.claude/engram-active-project.tmp')
    last = None
    if os.path.exists(state_file):
        with open(state_file) as f:
            last = f.read().strip()

    if project != last:
        with open(state_file, 'w') as f:
            f.write(project)
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": (
                    f"[ENGRAM ACTIVE PROJECT → {project}] "
                    f"Pass project='{project}' in all subsequent mem_save calls."
                ),
            }
        }))

except Exception:
    exit(0)
