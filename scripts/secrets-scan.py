#!/usr/bin/env python3
"""
PreToolUse hook: fires before Write or Edit operations.
Scans content being written for secrets, credentials, and private keys.
Prevents accidental commit of sensitive material to source files.
"""
import sys, json, re, os

# Secret patterns with labels — ordered by severity
SECRET_PATTERNS = [
    # Private keys — highest severity
    (r'-----BEGIN\s+(?:RSA\s+|EC\s+|DSA\s+|OPENSSH\s+)?PRIVATE\s+KEY',
     'SSH/TLS PRIVATE KEY', 'CRITICAL'),

    # Cloud provider credentials
    (r'AKIA[0-9A-Z]{16}',
     'AWS ACCESS KEY', 'CRITICAL'),
    (r'(?:aws_secret_access_key|AWS_SECRET)\s*[=:]\s*[A-Za-z0-9/+=]{20,}',
     'AWS SECRET KEY', 'CRITICAL'),

    # AI/API keys
    (r'sk-ant-[A-Za-z0-9\-_]{20,}',
     'ANTHROPIC API KEY', 'CRITICAL'),
    (r'\bsk-[A-Za-z0-9]{20,}\b',
     'OPENAI/AI API KEY', 'CRITICAL'),
    (r'ghp_[A-Za-z0-9]{36}',
     'GITHUB PERSONAL TOKEN', 'CRITICAL'),
    (r'ghs_[A-Za-z0-9]{36}',
     'GITHUB APP TOKEN', 'CRITICAL'),

    # Database credentials
    (r'(?:DB_PASSWORD|DATABASE_PASSWORD|POSTGRES_PASSWORD|db_pass(?:word)?)\s*[=:]\s*["\']?[^\s"\'#]{6,}',
     'DATABASE PASSWORD', 'HIGH'),

    # Generic secrets in code
    (r'(?:password|passwd)\s*=\s*["\'][^"\']{6,}["\']',
     'HARDCODED PASSWORD', 'HIGH'),
    (r'(?:secret_key|SECRET_KEY)\s*=\s*["\'][^"\']{10,}["\']',
     'SECRET KEY', 'HIGH'),
    (r'(?:api_key|API_KEY)\s*=\s*["\'][A-Za-z0-9_\-]{16,}["\']',
     'API KEY', 'HIGH'),

    # Odoo-specific
    (r'admin_passwd\s*=\s*[^\s#]{4,}',
     'ODOO MASTER PASSWORD', 'CRITICAL'),
]

# File extensions where these patterns are expected/safe (docs, examples)
SAFE_EXTENSIONS = {
    '.md', '.rst', '.txt', '.example', '.sample', '.template',
    '.test', '.spec', '.fixture', '.mock'
}

# File name patterns that are config templates — safe to have placeholders
SAFE_FILENAME_PATTERNS = [
    r'\.env\.example',
    r'\.env\.template',
    r'\.env\.sample',
    r'config\.example\.',
    r'docker-compose\.yml',  # docker-compose often has env var references, not real secrets
]


def is_safe_file(file_path):
    if not file_path:
        return False
    fp = file_path.replace('\\', '/').lower()
    ext = os.path.splitext(fp)[1]
    if ext in SAFE_EXTENSIONS:
        return True
    return any(re.search(p, fp) for p in SAFE_FILENAME_PATTERNS)


def is_env_var_reference(match_text):
    """True if the match looks like a reference ($VAR, ${VAR}) not an actual secret."""
    return bool(re.search(r'\$\{?\w+\}?', match_text))


try:
    data = json.load(sys.stdin)
    tool = data.get('tool_name', '')
    inp = data.get('tool_input', {})

    if tool not in ('Write', 'Edit'):
        sys.exit(0)

    file_path = inp.get('file_path', '')

    if is_safe_file(file_path):
        sys.exit(0)

    # Get content being written
    content = inp.get('content', '') or inp.get('new_string', '') or ''

    if not content or len(content) < 10:
        sys.exit(0)

    found = []
    for pattern, label, severity in SECRET_PATTERNS:
        match = re.search(pattern, content, re.IGNORECASE | re.MULTILINE)
        if match and not is_env_var_reference(match.group(0)):
            found.append((label, severity))

    if not found:
        sys.exit(0)

    critical = [label for label, sev in found if sev == 'CRITICAL']
    high     = [label for label, sev in found if sev == 'HIGH']

    parts = []
    if critical:
        parts.append(f"CRITICAL: {', '.join(critical)}")
    if high:
        parts.append(f"HIGH: {', '.join(high)}")

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": (
                f"[SECURITY ALERT — SECRETS DETECTED IN '{os.path.basename(file_path)}'] "
                f"Patterns found → {' | '.join(parts)}. "
                f"⛔ STOP — Do NOT write secrets to source code files. "
                f"Use environment variables (.env, gitignored) or secret vaults instead. "
                f"Verify this is intentional before proceeding. "
                f"If this is a test/example file, rename it with .example extension."
            )
        }
    }))

except Exception:
    pass
