#!/usr/bin/env python3
"""
SessionStart hook: fires when Claude Code starts a session.
Detects active workflow protocol (Odoo st_*/db_* or GitFlow) and injects
current git state as context. Exits silently if no .git found.
"""
import json, os, glob, subprocess

CWD = os.getcwd()

ODOO_ALLOWED    = lambda b: b.startswith('st_')
ODOO_RESTRICTED = lambda b: b == 'produccion' or b.startswith('db_')
GITFLOW_ALLOWED = lambda b: b in ('main', 'develop') or any(
    b.startswith(p) for p in ('feature/', 'release/', 'hotfix/', 'fix/', 'docs/')
)


def is_odoo_project():
    if os.path.exists(os.path.join(CWD, '__manifest__.py')):
        return True
    return bool(glob.glob(os.path.join(CWD, '*', '__manifest__.py')))


def is_git_repo():
    return os.path.exists(os.path.join(CWD, '.git'))


def git_run(*args):
    try:
        result = subprocess.run(
            ['git'] + list(args),
            capture_output=True, text=True, timeout=5, cwd=CWD
        )
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None


def current_branch():
    return git_run('branch', '--show-current')


def commits_ahead(base='origin/main'):
    count = git_run('rev-list', '--count', 'HEAD', f'^{base}')
    if count is None:
        count = git_run('rev-list', '--count', 'HEAD', f'^{base.replace("origin/", "")}')
    try:
        n = int(count)
        return n if n > 0 else None
    except (TypeError, ValueError):
        return None


def last_tag():
    return git_run('describe', '--tags', '--abbrev=0')


def classify_branch(branch, odoo):
    if odoo:
        if ODOO_ALLOWED(branch):
            return 'ALLOWED'
        if ODOO_RESTRICTED(branch):
            return 'RESTRICTED'
        return 'UNKNOWN'
    if GITFLOW_ALLOWED(branch):
        return 'ALLOWED'
    return 'UNKNOWN'


def build_message(branch, status, odoo, ahead, tag):
    if odoo:
        header   = '[WORKFLOW STATE — ODOO]'
        protocol = 'Allowed: st_* / st_produccion | Restricted: produccion / db_*'
        base_label = 'st_produccion'
    else:
        header   = '[WORKFLOW STATE — GITFLOW]'
        protocol = 'Allowed: main / develop / feature/* / release/* / hotfix/*'
        base_label = 'main'

    lines = [
        header,
        f'→ Branch: {branch} ({status})',
        f'→ Protocol: {protocol}',
    ]
    if ahead:
        lines.append(f'→ {ahead} commit(s) ahead of {base_label}')
    if tag:
        lines.append(f'→ Last tag: {tag}')
    if status == 'RESTRICTED':
        lines.append(
            f'→ ALERT: {branch} is a RESTRICTED branch. '
            'Ask explicit user authorization before any git operation.'
        )
    elif status == 'UNKNOWN':
        lines.append(
            f'→ WARNING: {branch} does not match expected branch pattern for this protocol.'
        )
    return '\n'.join(lines)


if not is_git_repo():
    exit(0)

odoo   = is_odoo_project()
branch = current_branch()

if not branch:
    exit(0)

status = classify_branch(branch, odoo)
base   = 'origin/st_produccion' if odoo else 'origin/main'
ahead  = commits_ahead(base)
tag    = last_tag()

print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': build_message(branch, status, odoo, ahead, tag)
    }
}))
