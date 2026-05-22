#!/usr/bin/env python3
"""
SessionStart hook: detects known engram projects in CWD.
Injects active project or multi-project list into model context.
Also loads AGENTS.md from the active project when in single-project mode.
Source of truth: ~/.claude/engram-sync-config.json
"""
import json, os


def read_agents_md(path):
    """Read AGENTS.md from project root. Returns content string or None."""
    agents_path = os.path.join(path, 'AGENTS.md')
    if not os.path.exists(agents_path):
        return None
    try:
        content = open(agents_path, encoding='utf-8', errors='ignore').read().strip()
        return content if content else None
    except Exception:
        return None


try:
    config_path = os.path.expanduser('~/.claude/engram-sync-config.json')
    with open(config_path) as f:
        config = json.load(f)
    known_projects = config.get('projects', [])
    cwd = os.getcwd()

    found = []  # list of (name, path)

    # Case 1: CWD is itself a known project repo
    if os.path.exists(os.path.join(cwd, '.git')):
        name = os.path.basename(cwd)
        if name in known_projects:
            found.append((name, cwd))
    else:
        # Case 2: CWD is a parent folder — scan one level down
        try:
            for entry in os.scandir(cwd):
                if entry.is_dir() and entry.name in known_projects:
                    if os.path.exists(os.path.join(entry.path, '.git')):
                        found.append((entry.name, entry.path))
        except PermissionError:
            pass

    if not found:
        exit(0)

    if len(found) == 1:
        name, path = found[0]
        msg = (
            f"[ENGRAM PROJECT DETECTED] Active project: {name}. "
            f"Pass project='{name}' in every mem_save call."
        )
        agents = read_agents_md(path)
        if agents:
            msg += f"\n\n[AGENTS.md — {name}]\n{agents}"
    else:
        names = [n for n, p in found]
        msg = (
            f"[ENGRAM MULTI-PROJECT] Projects in scope: {names}. "
            f"Pass project= explicitly in every mem_save based on which files you edit. "
            f"File-edit hooks will update the active project and load its AGENTS.md automatically."
        )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": msg,
        }
    }))

except Exception:
    exit(0)
