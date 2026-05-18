# OCA Guidelines Reference

## Official Sources

| Resource | URL |
|----------|-----|
| OCA Coding Guidelines | https://github.com/OCA/odoo-community.org/blob/master/website/Contribution/CONTRIBUTING.rst |
| OCA Maintainer Tools | https://github.com/OCA/maintainer-tools |
| OCA Pre-commit Config | https://github.com/OCA/oca-addons-repo-template |
| Odoo Guidelines (official) | https://www.odoo.com/documentation/17.0/contributing/development.html |

## Pre-commit Hooks (OCA Standard)

OCA repos use these linters via pre-commit:

| Hook | What it checks |
|------|---------------|
| `pylint-odoo` | Odoo-specific Python rules (manifest, imports, API usage) |
| `flake8` | PEP 8 style (max 120 chars for OCA) |
| `isort` | Import ordering (stdlib → third-party → odoo → odoo.addons) |
| `black` | Code formatting (OCA repos may or may not use it) |
| `prettier` | XML/JS formatting |
| `eslint` | JavaScript linting |

## Import Order

```python
# 1. Standard library
import logging
from datetime import datetime

# 2. Third-party (non-Odoo)
import requests

# 3. Odoo core
from odoo import api, fields, models
from odoo.exceptions import UserError, ValidationError
from odoo.tools import float_compare

# 4. Odoo addons (current module last)
from odoo.addons.sale.models.sale_order import SaleOrder
from odoo.addons.my_module.utils import helper_function
```

## Manifest Version Format

```text
{odoo_version}.{major}.{minor}.{patch}
```

| Segment | Meaning | Example |
|---------|---------|---------|
| `odoo_version` | Odoo series | `17.0` |
| `major` | Breaking changes | `1` (start at 1) |
| `minor` | New features | `0` |
| `patch` | Bug fixes | `0` |

First release: `17.0.1.0.0`
After a bugfix: `17.0.1.0.1`
After a feature: `17.0.1.1.0`
After breaking change: `17.0.2.0.0`

## Required Manifest Keys

```python
{
    'name': 'Module Human Name',           # REQUIRED
    'version': '17.0.1.0.0',              # REQUIRED — OCA format
    'summary': 'One-line description',      # REQUIRED
    'author': 'Author Name, OCA',          # REQUIRED — comma-separated
    'website': 'https://github.com/OCA/...',
    'license': 'LGPL-3',                   # REQUIRED — LGPL-3 or AGPL-3
    'category': 'Sales',                   # REQUIRED
    'depends': ['sale'],                   # REQUIRED — explicit dependencies
    'data': [],                            # views, security, data files
    'demo': [],                            # demo data (loaded with --demo)
    'installable': True,                   # REQUIRED
    'application': False,
    'auto_install': False,
}
```

## Folder Structure (OCA Standard)

```text
my_module/
├── __init__.py
├── __manifest__.py
├── controllers/
│   ├── __init__.py
│   └── main.py
├── data/
│   └── data.xml
├── demo/
│   └── demo.xml
├── models/
│   ├── __init__.py
│   └── my_model.py
├── report/
│   ├── __init__.py
│   └── report_template.xml
├── security/
│   ├── ir.model.access.csv
│   └── security.xml
├── static/
│   ├── description/
│   │   └── icon.png
│   └── src/
│       ├── js/
│       └── xml/
├── tests/
│   ├── __init__.py
│   └── test_my_model.py
├── views/
│   └── my_model_views.xml
└── wizard/
    ├── __init__.py
    └── my_wizard.py
```
