#!/usr/bin/env python3
"""
SessionStart hook: fires when Claude Code starts a session.
Detects Odoo project in CWD by checking for __manifest__.py.
Injects mandatory reminder to load odoo-development skill immediately.
"""
import json, os, glob

cwd = os.getcwd()

# Check CWD directly (module root)
manifest_direct = os.path.join(cwd, '__manifest__.py')

# Check one level down (workspace root with multiple modules)
manifest_child = glob.glob(os.path.join(cwd, '*', '__manifest__.py'))

if not os.path.exists(manifest_direct) and not manifest_child:
    exit(0)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": (
            "[ODOO PROJECT DETECTED] __manifest__.py found in working directory. "
            "MANDATORY — execute BEFORE any other action: "
            "(1) Load odoo-development skill. "
            "(2) Run scripts/odoo-version-detect.ps1 (version + edition). "
            "(3) Run scripts/module-intelligence.ps1 (10-step module analysis). "
            "Steps (2) and (3) run in PARALLEL. Do NOT write code until both complete."
        )
    }
}))
