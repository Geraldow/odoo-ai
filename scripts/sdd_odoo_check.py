#!/usr/bin/env python3
"""
PreToolUse hook: fires before Edit/Write/Read/Glob/Grep on Odoo project files.
Injects SDD compliance reminder when Odoo context is detected.
"""
import sys, json, os

ODOO_SOURCE_PATHS = [
    'Development/Odoo',
    'src/odoo',
    'src/enterprise',
    'src/user',
    '/odoo/',
]

def is_odoo_path(path):
    if not path:
        return False
    path_lower = path.replace('\\', '/')
    for odoo_path in ODOO_SOURCE_PATHS:
        if odoo_path in path_lower:
            return True
    # Walk up looking for __manifest__.py
    p = os.path.dirname(os.path.abspath(path)) if os.path.isfile(path) or not os.path.isdir(path) else os.path.abspath(path)
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

    # Extract the relevant path depending on tool
    check_path = (
        inp.get('file_path') or
        inp.get('path') or
        inp.get('pattern') or
        ''
    )

    if is_odoo_path(check_path):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "additionalContext": (
                    "[ODOO SDD GUARD] Accessing an Odoo project file. "
                    "MANDATORY CHECK: (1) Did you classify this task size? "
                    "(2) If Moderado/Moderate (2+ files / nueva logica) or Complejo/Complex (nuevo modulo / arquitectura): "
                    "STOP — run /sdd-ff FIRST before any exploration, reading, or code edits. "
                    "Do NOT proceed with inline work for Moderado/Complejo Odoo tasks."
                )
            }
        }))
except Exception:
    pass
