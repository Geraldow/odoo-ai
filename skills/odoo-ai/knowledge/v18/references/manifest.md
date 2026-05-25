---
title: Odoo 18 — Manifest Reference
domain: manifest
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Manifest Reference

## Core Keys

| Key | Type | Description |
| :--- | :--- | :--- |
| `name` | `str` | Display name of the module. |
| `version` | `str` | Module version (format: `18.0.x.x.x`). |
| `summary` | `str` | Short subtitle for the module. |
| `category` | `str` | Category in the App list (e.g., `Sales`, `Accounting`). |
| `author` | `str` | Name of the author/organization. |
| `website` | `str` | URL for the author/module website. |
| `license` | `str` | License (e.g., `LGPL-3`, `OPL-1`, `AGPL-3`). |
| `depends` | `list` | List of module dependencies. |
| `data` | `list` | Data files (XML, CSV) loaded on install/update. |
| `demo` | `list` | Data files loaded only when "Demo Data" is enabled. |
| `installable` | `bool` | Whether the module can be installed. Default: `True`. |
| `auto_install` | `bool/list` | If `True` or list of modules, installs automatically. |
| `application` | `bool` | If `True`, appears as a main "App". |
| `assets` | `dict` | Web assets (JS, CSS) grouped by bundle. |

## Assets Structure
```python
'assets': {
    'web.assets_backend': [
        'my_module/static/src/js/**/*.js',
        'my_module/static/src/xml/**/*.xml',
        'my_module/static/src/scss/style.scss',
    ],
    'web.assets_frontend': [
        # Website specific assets
    ],
},
```

## Standard Versioning
Odoo Community Association (OCA) and standard practice:
`[major].[minor].[patch]` -> `18.0.1.0.0`
- `18.0`: Odoo version.
- `1.0.0`: Module version.

## Data Loading Order
1. `depends` (recursively)
2. `data` (in order of definition)
3. `demo` (if applicable)
