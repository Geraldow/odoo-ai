---
title: Odoo 18 — Models Reference
domain: models
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Models Reference

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
| `_parent_name` | `str` | Field used as parent in hierarchy. | `parent_id` |

## Inheritance Patterns

### Class Inheritance (Extension)
Used to add fields or override methods in an existing model.
```python
class MyPartner(models.Model):
    _inherit = 'res.partner'

    custom_field = fields.Char("Custom")
```

### Prototype Inheritance (Copy)
Used to create a new model with all fields and methods of the parent.
```python
class MyModel(models.Model):
    _name = 'my.model'
    _inherit = 'mail.thread'
```

### Delegation Inheritance
Delegates fields to a linked model.
```python
class MyUser(models.Model):
    _name = 'my.user'
    _inherits = {'res.partner': 'partner_id'}

    partner_id = fields.Many2one('res.partner', required=True, ondelete='cascade')
```

## Special Fields (Automatic)

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `Integer` | Unique identifier (Primary Key). |
| `create_date` | `Datetime` | Record creation timestamp. |
| `create_uid` | `Many2one` | User who created the record (`res.users`). |
| `write_date` | `Datetime` | Last modification timestamp. |
| `write_uid` | `Many2one` | User who last modified the record. |
| `display_name` | `Char` | Computed name of the record. |
