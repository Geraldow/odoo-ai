#!/usr/bin/env python3
"""
PreToolUse hook: fires before Edit/Write on Odoo files.
- Edit/Write on any Odoo module file → SDD guard (classify task size)
"""
import sys, json, os


WRITE_TOOLS = {'Edit', 'Write'}


def is_odoo_module_file(path):
    """Walk up from path looking for __manifest__.py (custom module code)."""
    if not path:
        return False
    p = os.path.dirname(os.path.abspath(path)) if not os.path.isdir(path) else os.path.abspath(path)
    for _ in range(6):
        if os.path.exists(os.path.join(p, '__manifest__.py')):
            return True
        parent = os.path.dirname(p)
        if parent == p:
            break
        p = parent
    return False


try:
    data = json.load(sys.stdin)
    tool = data.get('tool_name', '')
    inp  = data.get('tool_input', {})

    if tool not in WRITE_TOOLS:
        sys.exit(0)

    check_path = inp.get('file_path') or inp.get('path') or ''

    if not is_odoo_module_file(check_path):
        sys.exit(0)

    msg = (
        "[ODOO SDD GUARD] About to modify an Odoo project file. "
        "MANDATORY: (1) Classify task size first. "
        "(2) Moderado (2+ files / new logic) or Complejo (new module / architecture): "
        "STOP — run /sdd-ff FIRST. Do NOT write inline for Moderado/Complejo tasks. "
        "(3) Load odoo-development skill BEFORE writing any code — "
        "run odoo-version-detect.ps1 + module-intelligence.ps1 in PARALLEL."
    )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": msg
        }
    }))
except Exception:
    pass
