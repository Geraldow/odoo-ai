---
title: Odoo 19 — Models Reference
domain: models
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Models Reference

## Model Types

| Class | Purpose | Persistence |
| :--- | :--- | :--- |
| `models.Model` | Main Odoo models. | Permanent (PostgreSQL) |
| `models.TransientModel` | Temporary data (wizards). | Temporary (auto-vacuum) |
| `models.AbstractModel` | Abstract base for multiple models. | None |

## Core Attributes

| Attribute | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| `_name` | `str` | Internal identifier (dots notation). | `None` |
| `_description` | `str` | User-friendly name of the model. | `None` |
| `_inherit` | `str/list` | Inheritance (extension or delegation). | `None` |
| `_inherits` | `dict` | Polymorphic inheritance (delegation). | `{}` |
| `_order` | `str` | SQL ordering clause. | `id` |
| `_rec_name` | `str` | Field used for name representation. | `name` |
| `_check_company_auto` | `bool` | Auto-validate company consistency. | `False` |
| `_table` | `str` | SQL table name. | `_name` (dots to underscores) |
| `_sql_constraints` | `list` | SQL-level constraints (name, sql, message). | `[]` |
| `_parent_store` | `bool` | Enables nested sets for fast hierarchy. | `False` |

## Type Hints (New in v19)
Odoo 19 standardizes the use of Python type hints for better IDE support and static analysis. Use string forward references for models.

```python
from odoo import models, fields

class ResPartner(models.Model):
    _inherit = 'res.partner'

    # Standard Type Hinting for fields
    category_id: 'ResPartnerCategory' = fields.Many2one('res.partner.category', string='Category')
    child_ids: 'ResPartner' = fields.One2many('res.partner', 'parent_id', string='Children')
```

## SQL Builder API (New in v19)
Odoo 19 introduces a programmatic SQL Builder to avoid raw string concatenation and prevent SQL injection.

```python
from odoo.tools.sql import SQL

def _get_custom_data(self):
    query = SQL(
        "SELECT id FROM %s WHERE active = %s",
        SQL.identifier(self._table),
        True
    )
    self.env.cr.execute(query)
    return self.env.cr.fetchall()
```

## Inheritance Patterns

### Class Inheritance (Extension)
```python
class MyPartner(models.Model):
    _inherit = 'res.partner'

    custom_field: str = fields.Char("Custom")
```

### Delegation Inheritance
```python
class MyUser(models.Model):
    _name = 'my.user'
    _inherits = {'res.partner': 'partner_id'}

    partner_id: 'ResPartner' = fields.Many2one('res.partner', required=True, ondelete='cascade')
```

## Special Fields (Automatic)

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `Integer` | Unique identifier (Primary Key). |
| `create_date` | `Datetime` | Record creation timestamp. |
| `create_uid` | `Many2one` | User who created the record. |
| `write_date` | `Datetime` | Last modification timestamp. |
| `display_name` | `Char` | Computed name (replaces `name_get` logic). |
| `active` | `Boolean` | Used for soft-deletion (archiving). |
