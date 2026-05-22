#!/usr/bin/env python3
"""
UserPromptSubmit / PostCompact hook: Odoo skill enforcement per prompt.

Fires before every user message (UserPromptSubmit) and after compaction (PostCompact).
Detects Odoo project by CWD (depth 0/1/2), reads user message for humanized
intent keywords in ES+EN, injects targeted odoo-development reminders.

Never blocks session — all logic wrapped in try/except with exit(0) on error.
"""
import json, sys, os, glob

# ── HUMANIZED INTENT KEYWORDS (ES + EN) ──────────────────────────────────────
# These are natural-language phrases developers actually write, not technical terms.

# Module exploration → invoke odoo-source before coding
EXPLORATION_KEYWORDS = [
    # UI location — español
    'formulario de', 'formulario del', 'en el formulario', 'en la lista',
    'en el kanban', 'pantalla de', 'pantalla del', 'vista de', 'en la vista',
    'pestaña', 'sección de', 'botón en', 'botón de', 'campo en',
    'aparezca en', 'aparezca también', 'muestre en', 'mostrar en',
    'columna en', 'columna de', 'añadir al', 'agregar al',
    # UI location — inglés
    'in the form', 'in the list', 'on the form', 'form view', 'list view',
    'add to the form', 'show in the', 'add a tab', 'add a button',
    'add a field to', 'column in', 'appear in',
    # Inheritance / customization — español
    'hereda', 'hereda de', 'extiende', 'extender', 'personaliza',
    'personalizar', 'modificar el comportamiento', 'cambiar cómo',
    'agregar al módulo', 'añadir al módulo',
    # Inheritance — inglés
    'override', 'extend', 'inherit from', 'customize', 'modify how',
    # Module understanding — español
    'cómo funciona', 'qué hace', 'de dónde viene', 'cómo está construido',
    'cómo está hecho', 'qué modelo usa', 'qué vista usa',
    # Module understanding — inglés
    'how does', 'where is defined', 'what model', 'how is it built', 'where does it come',
    # Odoo business domains in natural language — español
    'orden de venta', 'pedido de venta', 'orden de compra', 'pedido de compra',
    'factura de cliente', 'factura de proveedor', 'nota de crédito',
    'punto de venta', 'sesión de caja', 'cierre de caja', 'turno de caja',
    'nómina', 'planilla', 'liquidación', 'asistencia del empleado',
    'inventario', 'almacén', 'movimiento de stock', 'traslado de mercancía',
    'módulo de ventas', 'módulo de compras', 'módulo de contabilidad',
    # Odoo business domains — inglés
    'sale order', 'purchase order', 'vendor bill', 'customer invoice',
    'point of sale', 'pos session', 'payroll', 'employee contract',
    'inventory move', 'warehouse transfer',
]

# ORM / field / model work → odoo-development fhidalgo/unclecatvn plugin
ORM_KEYWORDS = [
    # Campo — español
    'campo nuevo', 'agregar campo', 'añadir campo', 'crear campo', 'nuevo campo',
    # Triggers on state/action — español
    'cuando se confirma', 'cuando se valida', 'cuando se guarda',
    'cuando se aprueba', 'al confirmar', 'al guardar', 'al validar',
    'al aprobar', 'cuando cambie', 'cuando el usuario',
    # Computed / related — español
    'calcular automáticamente', 'que se calcule', 'valor automático',
    'se recalcule', 'campo calculado', 'campo computado', 'depende de',
    # Constraints — español
    'restricción', 'validar que', 'no puede ser', 'debe ser', 'no permite',
    'que valide', 'que no permita',
    # Sequences — español
    'secuencia', 'numeración automática', 'número correlativo',
    # Campo — inglés
    'new field', 'add field', 'when confirmed', 'when validated', 'when saved',
    'when approved', 'auto calculate', 'computed field', 'constraint',
    'must be', 'cannot be', 'sequence', 'auto number', 'depends on',
]

# Reports → ahmedlakos plugin
REPORT_KEYWORDS = [
    'reporte', 'informe', 'pdf', 'imprimir', 'impresión',
    'plantilla de reporte', 'plantilla de impresión', 'generar pdf',
    'report', 'print', 'pdf template', 'qweb report', 'generate pdf',
]

# Security → security guide (odoo-development)
SECURITY_KEYWORDS = [
    'permisos', 'acceso', 'quién puede', 'grupo de usuarios',
    'regla de registro', 'sin acceso', 'no puede ver', 'no puede editar',
    'solo puede ver', 'solo lectura para', 'restringir acceso',
    'permissions', 'access rights', 'who can', 'user group',
    'record rule', 'cannot see', 'read only for', 'restrict access',
]


def is_odoo_project(cwd):
    """Detect Odoo project at depth 0, 1, or 2 from CWD."""
    if os.path.exists(os.path.join(cwd, '__manifest__.py')):
        return True
    if glob.glob(os.path.join(cwd, '*', '__manifest__.py')):
        return True
    if glob.glob(os.path.join(cwd, '*', '*', '__manifest__.py')):
        return True
    return False


def detect_any(text, keywords):
    """Case-insensitive substring match for any keyword."""
    text_lower = text.lower()
    return any(kw.lower() in text_lower for kw in keywords)


try:
    event_name = sys.argv[1] if len(sys.argv) > 1 else "UserPromptSubmit"

    data = json.load(sys.stdin)

    cwd = os.getcwd()
    if not is_odoo_project(cwd):
        sys.exit(0)

    # Extract user message — try multiple field names (format varies by Claude Code version)
    message = (
        data.get('message', '')
        or data.get('prompt', '')
        or data.get('tool_input', {}).get('message', '')
        or ''
    )

    # Base reminder — always present when in Odoo project
    parts = [
        "[ODOO SKILL REQUIRED] Odoo project detected. "
        "MANDATORY: load odoo-development skill FIRST. "
        "Run odoo-version-detect.ps1 + module-intelligence.ps1 in PARALLEL before any code."
    ]

    # Keyword-targeted additions (only when message is available)
    if message:
        if detect_any(message, EXPLORATION_KEYWORDS):
            parts.append(
                "[ODOO-SOURCE TRIGGER] Module/view exploration detected — "
                "invoke odoo-source plugin to analyze the target module "
                "(fields, views, xpaths, controllers, flow) BEFORE writing any code."
            )
        elif detect_any(message, ORM_KEYWORDS):
            parts.append(
                "[ORM CONTEXT] Field/model/compute change detected — "
                "use fhidalgo or unclecatvn plugin (odoo-development) for v18 ORM patterns."
            )

        if detect_any(message, REPORT_KEYWORDS):
            parts.append(
                "[REPORT CONTEXT] Use ahmedlakos plugin for QWeb/PDF report patterns."
            )

        if detect_any(message, SECURITY_KEYWORDS):
            parts.append(
                "[SECURITY CONTEXT] Load security guide from odoo-development "
                "before modifying access rules or groups."
            )

    reminder = " | ".join(parts)

    # Output format: additionalContext for UserPromptSubmit, systemMessage for PostCompact
    if event_name == "PostCompact":
        print(json.dumps({"systemMessage": reminder}))
    else:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": event_name,
                "additionalContext": reminder
            }
        }))

except Exception:
    sys.exit(0)
