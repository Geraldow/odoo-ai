# ODSK-SKL-MODULE | Asset: manifest_full.py
# Full __manifest__.py showing all common fields.
# Remove fields you don't need — don't leave empty strings or False values.

{
    # ── Identity ──────────────────────────────────────────────────────────────

    # The human-readable name shown in the Apps menu.
    "name": "Sale Stock Bridge",

    # Odoo version prefix + semantic version.
    # Convention: {odoo_major}.0.{major}.{minor}.{patch}
    # Always start a new module at x.0.1.0.0
    "version": "17.0.1.0.0",

    # Short description shown under the module name in the Apps menu.
    "summary": "Connects Sale and Stock for joint workflows.",

    # Long description shown in the module detail page (plain text or RST).
    "description": """
Sale Stock Bridge
=================
This module activates automatically when both sale and stock are installed.
It enables shared workflows between sales orders and stock picking.
    """,

    # ── Attribution ────────────────────────────────────────────────────────────

    "author": "Geraldow",
    "website": "https://github.com/Yven-Labs",

    # Category shown in the Apps menu filter.
    # Use one of Odoo's standard categories (e.g. "Sales", "Inventory", "Accounting").
    "category": "Sales/Inventory",

    # SPDX license identifier.
    # Common choices: LGPL-3, GPL-3, OPL-1 (proprietary)
    "license": "LGPL-3",

    # ── Dependencies ───────────────────────────────────────────────────────────

    # Every module listed here MUST be installed before this module can install.
    # Odoo will enforce this. Be precise — don't list modules you don't actually use.
    "depends": ["sale_management", "stock"],

    # When True, Odoo auto-installs this module the moment ALL modules in
    # `depends` are installed. Use this for bridge/glue modules only.
    # Default is False — never set True unless this is a bridge module.
    "auto_install": True,

    # ── Data Files ─────────────────────────────────────────────────────────────

    # Files loaded at INSTALL and UPGRADE time, in the order listed.
    # Always load security first, then views, then data.
    "data": [
        "security/ir.model.access.csv",
        "views/sale_order_views.xml",
        "data/default_data.xml",
    ],

    # Files loaded ONLY in demo databases (runbot, local dev with --load-demo).
    "demo": [
        "demo/demo_data.xml",
    ],

    # ── Behavior Flags ─────────────────────────────────────────────────────────

    # Must be True for the module to appear in Apps and be installable by users.
    "installable": True,

    # When True, the module appears in the main Apps menu with a large icon.
    # Use only for top-level app modules, not for technical or bridge modules.
    "application": False,
}
