#!/usr/bin/env python3
"""
PreToolUse hook: fires before Edit/Write/Read/Glob/Grep on Odoo project files.
- Edit/Write  → SDD guard (classify task size before modifying)
- Read/Glob/Grep → redirect to codesearch MCP (avoid bloating context)
"""
import sys, json, os

ODOO_SOURCE_PATHS = [
    'Development/Odoo',
    'src/odoo',
    'src/enterprise',
    'src/user',
    '/odoo/',
]

READ_TOOLS  = {'Read', 'Glob', 'Grep'}
WRITE_TOOLS = {'Edit', 'Write'}


def is_odoo_path(path):
    if not path:
        return False
    path_lower = path.replace('\\', '/')
    for odoo_path in ODOO_SOURCE_PATHS:
        if odoo_path in path_lower:
            return True
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

    check_path = (
        inp.get('file_path') or
        inp.get('path') or
        inp.get('pattern') or
        ''
    )

    if not is_odoo_path(check_path):
        sys.exit(0)

    if tool in READ_TOOLS:
        msg = (
            "[USE MCP CODESEARCH] You are about to use a built-in search/read tool on Odoo source. "
            "Use the codesearch MCP tool instead — it searches the indexed enterprise source "
            "(86,859 chunks) with semantic precision and does NOT bloat the context window. "
            "Built-in Read/Glob/Grep on Odoo source consumes large amounts of context tokens."
        )
    elif tool in WRITE_TOOLS:
        msg = (
            "[ODOO SDD GUARD] About to modify an Odoo project file. "
            "MANDATORY: (1) Classify task size first. "
            "(2) Moderado (2+ files / new logic) or Complejo (new module / architecture): "
            "STOP — run /sdd-ff FIRST. Do NOT write inline for Moderado/Complejo tasks."
        )
    else:
        sys.exit(0)

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": msg
        }
    }))
except Exception:
    pass
