#!/usr/bin/env python3
"""
PostToolUse hook: fires after SSH/psql commands that access client servers.
Injects strict data privacy rules to prevent customer PII from being
saved to Engram, committed to repos, or leaked outside the debug session.

Scope: Odoo.sh production/staging servers accessed via SSH.
"""
import sys, json, re

# Patterns that identify commands touching remote client environments
REMOTE_ACCESS_PATTERNS = [
    r'\bssh\b.*@.*\.odoo\.com',
    r'\bssh\b.*@.*\.dev\.odoo\.com',
    r'\bpsql\b.*\$(?:DATABASE|PGDATABASE|DATABASE_URL)',
    r'\bpsql\b.*-d\s+\S+',
]

# Odoo.sh production indicators (non-staging)
PRODUCTION_INDICATORS = [
    r'@\w+\.odoo\.com',                  # produccion.odoo.com
    r'@\w+-\w+-produccion-\d+',          # xxx-produccion-12345
    r'@aeca\.odoo\.com',
    r'@levantecovial\.odoo\.com',
    r'@gwong\.odoo\.com',
]


def is_remote_access(command):
    return any(re.search(p, command, re.IGNORECASE) for p in REMOTE_ACCESS_PATTERNS)


def is_production(command):
    return any(re.search(p, command, re.IGNORECASE) for p in PRODUCTION_INDICATORS)


try:
    data = json.load(sys.stdin)
    tool = data.get('tool_name', '')

    if tool != 'Bash':
        sys.exit(0)

    command = data.get('tool_input', {}).get('command', '')

    if not is_remote_access(command):
        sys.exit(0)

    prod = is_production(command)
    env_label = "PRODUCCIÓN" if prod else "staging"
    urgency = "🔴 PRODUCCIÓN —" if prod else "🟡 Staging —"

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": (
                f"[PRIVACIDAD DE DATOS — {urgency} servidor {env_label}] "
                f"Este comando accedió a un servidor remoto con datos de clientes. "
                f"REGLAS OBLIGATORIAS DE MANEJO DE DATOS: "
                f"(1) NUNCA guardar en Engram: nombres, RUC, DNI, emails, transacciones financieras, nóminas, o cualquier PII. "
                f"(2) NUNCA incluir datos de clientes en commits, PRs, comentarios de código, o mensajes de chat. "
                f"(3) Usar los datos SOLO para la tarea de debugging inmediata — no retenerlos. "
                f"(4) Si debes referenciar un dato en tu respuesta, enmascararlo: RUC 20XXXXXXX12, email u***@dominio.com. "
                f"(5) En caso de ver datos financieros sensibles (saldos, pagos, facturas) — confirmar con el usuario antes de mostrarlos. "
                f"Cumplimiento con Ley 29733 (Perú) de Protección de Datos Personales."
            )
        }
    }))

except Exception:
    pass
