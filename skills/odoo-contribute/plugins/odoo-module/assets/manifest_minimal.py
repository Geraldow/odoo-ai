# ODSK-SKL-MODULE | Asset: manifest_minimal.py
# Minimal __manifest__.py for an Odoo module.
# Use this as your starting point — add fields only when you need them.

{
    # REQUIRED — the only truly mandatory field.
    # Must match the folder name of your module.
    "name": "My Module",

    # RECOMMENDED — Odoo version prefix + semantic version.
    # Format: {odoo_major}.0.{major}.{minor}.{patch}
    "version": "17.0.1.0.0",

    # RECOMMENDED — One-line description shown in the Apps menu.
    "summary": "Short description of what this module does.",

    # RECOMMENDED — Who wrote it.
    "author": "Your Name or Company",

    # RECOMMENDED — Use a standard SPDX identifier.
    "license": "LGPL-3",

    # RECOMMENDED — List every Odoo module this module needs to work.
    # Odoo will refuse to install your module if these are not installed first.
    "depends": ["base"],

    # REQUIRED for the module to be loadable —
    # list all XML/CSV files that must be loaded at install time.
    "data": [],

    # Allows the module to appear in the Apps menu and be installed by users.
    "installable": True,
}
