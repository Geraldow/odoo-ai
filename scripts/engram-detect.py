#!/usr/bin/env python3
"""
SessionStart hook: detects known engram projects in CWD.
Injects active project or multi-project list into model context.
Source of truth: ~/.claude/engram-sync-config.json
"""
import json, os

try:
    config_path = os.path.expanduser('~/.claude/engram-sync-config.json')
    with open(config_path) as f:
        config = json.load(f)
    known_projects = config.get('projects', [])
    cwd = os.getcwd()

    found = []
    # Case 1: CWD is itself a known project repo
    if os.path.exists(os.path.join(cwd, '.git')):
        name = os.path.basename(cwd)
        if name in known_projects:
            found.append(name)
    else:
        # Case 2: CWD is a parent folder — scan one level down
        try:
            for entry in os.scandir(cwd):
                if entry.is_dir() and entry.name in known_projects:
                    if os.path.exists(os.path.join(entry.path, '.git')):
                        found.append(entry.name)
        except PermissionError:
            pass

    if not found:
        exit(0)

    if len(found) == 1:
        msg = (
            f"[ENGRAM PROJECT DETECTED] Active project: {found[0]}. "
            f"Pass project='{found[0]}' in every mem_save call."
        )
    else:
        msg = (
            f"[ENGRAM MULTI-PROJECT] Projects in scope: {found}. "
            f"Pass project= explicitly in every mem_save based on which files you edit. "
            f"File-edit hooks will update the active project automatically."
        )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": msg,
        }
    }))

except Exception:
    exit(0)
