---
name: odoo-oca
description: >
  Guides AI agents to follow OCA (Odoo Community Association) conventions for
  naming, versioning, folder structure, and Python style. Prevents common
  naming mistakes and enforces community standards.
  Trigger: When creating Odoo modules, naming models/fields/methods, writing
  manifests, or organizing module files.
license: MIT
metadata:
  author: Geraldow
  version: "1.0.0"
  scope: [root, core]
  supported_versions: ["17", "18"]
  default_version: "18"
  detect_from: "__manifest__.py"
  skill_id: ODSK-SKL-OCA
  auto_invoke:
    - "Following OCA conventions"
    - "Naming Odoo modules, models, or fields"
    - "Writing __manifest__.py version or metadata"
    - "Organizing module folder structure"
---

## When to Use

Load this skill when:

- Creating a new Odoo module and choosing its technical name
- Naming models, fields, or methods
- Writing or reviewing `__manifest__.py`
- Organizing files within a module (where to put views, security, data)
- Ensuring Python code follows OCA style (imports, line length, docstrings)
- Preparing a module for OCA contribution

---

## Version Detection

Before writing any code, detect the Odoo version:

1. Read `__manifest__.py` in the current directory or parent directories
2. Extract the `version` field (e.g., `"17.0.1.0.0"`)
3. The first segment is the Odoo version (`17` or `18`)
4. If no manifest found, use `default_version: "18"`

---

## Critical Rules

These rules prevent **OCA CI failures** and **naming conflicts**:

### NEVER use CamelCase in technical names

```python
# ❌ WRONG — CamelCase in _name
class SaleReport(models.Model):
    _name = 'SaleReport'

# ✅ CORRECT — dotted lowercase
class SaleReport(models.Model):
    _name = 'sale.report'
    _description = 'Sale Report'
```

### NEVER omit _description on new models

```python
# ❌ WRONG — missing _description, OCA lint will fail
class SaleReport(models.Model):
    _name = 'sale.report'

# ✅ CORRECT
class SaleReport(models.Model):
    _name = 'sale.report'
    _description = 'Sale Report'
```

### NEVER use wrong suffix for relational fields

```python
# ❌ WRONG — Many2one without _id, One2many without _ids
partner = fields.Many2one('res.partner')
lines = fields.One2many('sale.order.line', 'order_id')

# ✅ CORRECT
partner_id = fields.Many2one('res.partner', string='Customer')
line_ids = fields.One2many('sale.order.line', 'order_id', string='Lines')
```

### NEVER use wrong version format in manifest

```python
# ❌ WRONG — missing odoo version prefix
'version': '1.0.0',

# ❌ WRONG — only 3 segments after prefix
'version': '17.0.1.0',

# ✅ CORRECT — {odoo}.{major}.{minor}.{patch}
'version': '17.0.1.0.0',
```

---

## Module Naming Rules

| Rule | Example |
|------|---------|
| Lowercase with underscores | `sale_custom_report` |
| Prefix with domain module | `hr_attendance_overtime` |
| No hyphens | ~~`sale-report`~~ → `sale_report` |
| No version suffixes | ~~`sale_report_v2`~~ → `sale_report_extended` |
| No generic names | ~~`my_module`~~ → `sale_margin_analysis` |

---

## Model Naming Rules

| Rule | Example |
|------|---------|
| Dotted lowercase | `sale.custom.report` |
| Match module prefix | Module `sale_custom` → `sale.custom.*` |
| `_description` REQUIRED | `_description = 'Custom Sales Report'` |
| Python class: CamelCase | `class SaleCustomReport(models.Model)` |

---

## Field Naming Rules

| Suffix | Field Type | Example |
|--------|-----------|---------|
| `_id` | Many2one | `partner_id`, `company_id` |
| `_ids` | One2many / Many2many | `line_ids`, `tag_ids` |
| `_count` | Integer (computed) | `line_count`, `task_count` |
| `_date` | Date / Datetime | `start_date`, `confirmation_date` |
| `is_*` / `_is_*` | Boolean | `is_done`, `is_confirmed` |
| `has_*` / `_has_*` | Boolean | `has_attachment` |

---

## Method Naming Rules

| Prefix | Purpose | Example |
|--------|---------|---------|
| `_compute_*` | Computed field | `_compute_total` |
| `_inverse_*` | Inverse of computed | `_inverse_total` |
| `_search_*` | Custom search | `_search_total` |
| `_onchange_*` | Onchange handler | `_onchange_partner_id` |
| `_check_*` | Constraint | `_check_date_range` |
| `action_*` | Button (public) | `action_confirm` |
| `_action_*` | Button (private) | `_action_send_email` |
| `_prepare_*` | Build value dict | `_prepare_invoice_values` |
| `_get_*` | Retrieve data | `_get_default_company` |

---

## Python Style (OCA)

### Import Order

```python
# 1. stdlib
import logging
from datetime import datetime

# 2. third-party
import requests

# 3. odoo core
from odoo import api, fields, models
from odoo.exceptions import UserError, ValidationError

# 4. odoo addons
from odoo.addons.sale.models.sale_order import SaleOrder
```

### Line Length

- **Maximum**: 120 characters (OCA standard, not PEP 8's 79)

### Class Docstrings

```python
class SaleReport(models.Model):
    """Custom sales report with margin analysis.

    Extends the base sale report to include margin calculations
    and custom grouping by sales team.
    """
    _name = 'sale.report.custom'
    _description = 'Custom Sales Report'
```

---

## Folder Structure

Every module MUST organize files as:

```text
my_module/
├── __init__.py
├── __manifest__.py
├── models/          ← Python model files
├── views/           ← XML view definitions
├── security/        ← ir.model.access.csv + security.xml
├── data/            ← Static data (XML/CSV)
├── demo/            ← Demo data (loaded with --demo)
├── wizard/          ← TransientModel wizards
├── controllers/     ← HTTP controllers
├── report/          ← QWeb report templates
├── static/          ← CSS, JS, images
│   └── description/
│       └── icon.png ← Module icon (required for OCA)
└── tests/           ← Python test files
```

---

## XML ID Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Form view | `view_{model}_form` | `view_sale_report_form` |
| Tree view | `view_{model}_tree` | `view_sale_report_tree` |
| Search view | `view_{model}_search` | `view_sale_report_search` |
| Kanban view | `view_{model}_kanban` | `view_sale_report_kanban` |
| Action | `action_{model}` | `action_sale_report` |
| Menu root | `menu_{model}_root` | `menu_sale_report_root` |
| Menu item | `menu_{model}` | `menu_sale_report` |
| Group | `group_{role}` | `group_sale_manager` |
| Record rule | `rule_{model}_{scope}` | `rule_sale_report_company` |
| Sequence | `seq_{model}` | `seq_sale_report` |

---

## Assets

- [naming-cheatsheet.py](assets/naming-cheatsheet.py) — Quick reference with GOOD/BAD examples for all naming conventions

## References

- [oca-guidelines.md](references/oca-guidelines.md) — Official OCA links, pre-commit hooks, import order, manifest format, folder structure
