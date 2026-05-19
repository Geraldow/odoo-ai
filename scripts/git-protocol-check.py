#!/usr/bin/env python3
"""
PreToolUse hook: fires before any Bash command.
Intercepts git/gh operations and injects git protocol reminder into Claude context.
"""
import sys, json, os, re

GIT_PATTERNS = {
    'commit':      re.compile(r'\bgit\s+commit\b'),
    'push':        re.compile(r'\bgit\s+push\b'),
    'pull':        re.compile(r'\bgit\s+pull\b'),
    'branch':      re.compile(r'\bgit\s+(branch\b|checkout\s+-[bB]\b|switch\s+-[cC]\b)'),
    'cherry_pick': re.compile(r'\bgit\s+cherry-pick\b'),
    'merge':       re.compile(r'\bgit\s+merge\b'),
    'rebase':      re.compile(r'\bgit\s+rebase\b'),
    'reset':       re.compile(r'\bgit\s+reset\b'),
    'tag':         re.compile(r'\bgit\s+tag\b'),
    'stash':       re.compile(r'\bgit\s+stash\b'),
    'clone':       re.compile(r'\bgit\s+clone\b'),
    'gh_pr':       re.compile(r'\bgh\s+pr\b'),
    'gh_release':  re.compile(r'\bgh\s+release\b'),
}

PAUSE_OPS = {'push', 'cherry_pick', 'merge', 'rebase', 'reset', 'tag', 'gh_release'}


def classify(cmd):
    for op, pattern in GIT_PATTERNS.items():
        if pattern.search(cmd):
            return op
    return None


def is_odoo_project():
    return os.path.exists(os.path.join(os.getcwd(), '__manifest__.py'))


def build_message(op, odoo):
    if op == 'gh_pr':
        lines = [
            "[GIT PROTOCOL]",
            "→ Load odoo-contribute (odoo-pr plugin) before creating the PR.",
            "→ Run PR checklist from skill. Verify CI passes on source branch first.",
        ]
        return "\n".join(lines)

    if op == 'gh_release':
        lines = [
            "[GIT PROTOCOL]",
            "→ Load odoo-contribute before creating release.",
            "→ PAUSE — release creation requires explicit user authorization.",
        ]
        return "\n".join(lines)

    prefix = "[GIT PROTOCOL — ODOO]" if odoo else "[GIT PROTOCOL — GITFLOW]"
    branch_rule = (
        "branch must be st_* or st_produccion"
        if odoo else
        "branch must follow GitFlow: main / develop / feature/* / release/* / hotfix/*"
    )

    lines = [
        prefix,
        "→ Load odoo-contribute skill before proceeding.",
        f"→ Verify: {branch_rule}.",
    ]

    if op in PAUSE_OPS:
        op_label = op.replace('_', '-')
        lines.append(
            f"→ PAUSE — {op_label} requires explicit user authorization. "
            "Wait for 'sí, autorizo' before executing."
        )
    elif op == 'commit':
        lines.append(
            "→ Conventional commit format: "
            "feat|fix|docs|style|chore|refactor|perf|test(scope): message"
        )
    elif op == 'branch':
        if odoo:
            lines.append("→ New branch must be: st_<project-name>")
        else:
            lines.append(
                "→ New branch must follow: feature/*, fix/*, docs/*, "
                "release/v*, hotfix/*"
            )
    elif op == 'clone':
        lines.append("→ After clone, verify target directory and branch strategy.")

    return "\n".join(lines)


try:
    data = json.load(sys.stdin)
    if data.get('tool_name') != 'Bash':
        sys.exit(0)

    cmd = data.get('tool_input', {}).get('command', '')
    op  = classify(cmd)

    if not op:
        sys.exit(0)

    msg = build_message(op, is_odoo_project())

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": msg
        }
    }))
except Exception:
    pass
