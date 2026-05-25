---
title: Odoo 19 — Manifest Reference
domain: manifest
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Manifest Reference

## New and Critical Keys in v19

| Key | Type | Description |
| :--- | :--- | :--- |
| `auto_install` | `list` | **Strict Rule:** All modules in this list must also be in `depends`. |
| `countries` | `list` | ISO country codes (e.g., `['pe']`) for localization modules. |
| `module_type` | `str` | Classification: `official`, `industry`, `learning`. |
| `cloc_exclude` | `list` | Patterns to exclude from Odoo.sh line count. Supports recursive globs `**/*`. |
| `license` | `str` | **Mandatory.** Must be a valid identifier (`LGPL-3`, `OPL-1`, `AGPL-3`). |

## Standard Manifest Structure
```python
{
    'name': 'Module Name',
    'version': '19.0.1.0.0', # [Odoo Version].[Major].[Minor].[Patch]
    'category': 'Industry/Accounting',
    'summary': 'Short description of the module.',
    'author': 'Your Name',
    'website': 'https://www.example.com',
    'license': 'LGPL-3',
    'depends': [
        'base',
        'account', # If auto_install triggers on this, it MUST be here
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/my_model_views.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'my_module/static/src/js/**/*.js',
            'my_module/static/src/xml/**/*.xml',
        ],
    },
    'auto_install': ['account'],
    'installable': True,
    'application': False,
    'cloc_exclude': [
        'static/lib/**/*',
    ],
}
```

## Assets Bundles (v19 Note)
- `web.assets_backend`: Main backend JS/CSS.
- `web.assets_frontend`: Website/Portal JS/CSS.
- `_assets_pos`: Updated bundle name for Point of Sale assets.

## Data Loading Sequence
1.  **Dependencies:** Modules in `depends` are loaded recursively.
2.  **Static Data:** Files in `data` (XML, CSV).
3.  **Demo Data:** Only if demo mode is enabled.
4.  **Post-Init Hooks:** Python functions executed after installation.
