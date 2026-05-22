#!/usr/bin/env python3
"""
PreToolUse hook: fires before Edit/Write/Read/Glob/Grep on Odoo files.
- Read/Glob/Grep on enterprise/community SOURCE  → redirect to codesearch MCP
- Edit/Write on any Odoo module file             → SDD guard (classify task size)
"""
import sys, json, os

# Only these paths should trigger the codesearch redirect for Read operations.
# Must be specific enough to avoid matching custom module files or workspace config.
ENTERPRISE_SOURCE_PATHS = [
    'Development/Odoo/Source',
    'Development/Odoo/18/Source',
    '/home/odoo/src/odoo/',
    '/home/odoo/src/enterprise/',
    'src/odoo',
    'src/enterprise',
]

READ_TOOLS  = {'Read', 'Glob', 'Grep'}
WRITE_TOOLS = {'Edit', 'Write'}


def is_enterprise_source(path):
    """True only for Odoo enterprise/community source trees — NOT custom modules."""
    if not path:
        return False
    path_lower = path.replace('\\', '/')
    return any(p in path_lower for p in ENTERPRISE_SOURCE_PATHS)


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

    check_path = (
        inp.get('file_path') or
        inp.get('path') or
        inp.get('pattern') or
        ''
    )

    if tool in READ_TOOLS:
        if not is_enterprise_source(check_path):
            sys.exit(0)
        msg = (
            "[USE MCP CODESEARCH] You are reading Odoo enterprise/community source. "
            "Use the codesearch MCP tool instead — it searches the indexed source "
            "with semantic precision and does NOT bloat the context window. "
            "Built-in Read/Glob/Grep on 678-module enterprise source consumes large amounts of context tokens."
        )

    elif tool in WRITE_TOOLS:
        if not is_odoo_module_file(check_path) and not is_enterprise_source(check_path):
            sys.exit(0)
        msg = (
            "[ODOO SDD GUARD] About to modify an Odoo project file. "
            "MANDATORY: (1) Classify task size first. "
            "(2) Moderado (2+ files / new logic) or Complejo (new module / architecture): "
            "STOP — run /sdd-ff FIRST. Do NOT write inline for Moderado/Complejo tasks. "
            "(3) Load odoo-development skill BEFORE writing any code — "
            "run odoo-version-detect.ps1 + module-intelligence.ps1 in PARALLEL."
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
