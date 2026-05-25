---
title: Odoo 18 — Fields Reference
domain: fields
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Fields Reference

## Common Parameters (kwargs)

| Parameter | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| `string` | `str` | Label shown in views. | capitalized field name |
| `help` | `str` | Tooltip for the field. | `None` |
| `readonly` | `bool` | Field is not editable. | `False` |
| `required` | `bool` | Field must have a value. | `False` |
| `index` | `bool` | Create a database index. | `False` |
| `default` | `any/fn` | Default value or function returning it. | `None` |
| `groups` | `str` | XML IDs of groups that can access the field. | `None` |
| `copy` | `bool` | Field value is copied on `copy()`. | `True` |
| `translate` | `bool` | Enables multi-language support. | `False` |
| `tracking` | `bool/int` | Log changes in chatter (Odoo Enterprise/Mail). | `False` |

## Simple Field Types

| Type | Python Type | SQL Type | Notes |
| :--- | :--- | :--- | :--- |
| `Boolean` | `bool` | `BOOL` | |
| `Integer` | `int` | `INT4` | |
| `Float` | `float` | `NUMERIC` | Use `digits=(precision, scale)` |
| `Monetary` | `float` | `NUMERIC` | Requires `currency_field` attr |
| `Char` | `str` | `VARCHAR` | Max length via `size` |
| `Text` | `str` | `TEXT` | Multi-line text |
| `Html` | `str` | `TEXT` | Sanitized HTML content |
| `Date` | `date` | `DATE` | |
| `Datetime` | `datetime` | `TIMESTAMP` | Stored in UTC |
| `Binary` | `bytes` | `BYTEA` | For files/images |
| `Selection` | `str` | `VARCHAR` | `selection=[('key', 'Label')]` |
| `Reference` | `str` | `VARCHAR` | Dynamic relation `('model', id)` |

## Relational Field Types

### Many2one
Link to another record (Foreign Key).
- `comodel_name`: Name of the target model (required).
- `ondelete`: Action on deletion (`cascade`, `set null`, `restrict`). Default: `set null`.
- `delegate`: If `True`, creates delegation inheritance.

### One2many
Virtual link representing the "inverse" of a Many2one.
- `comodel_name`: Name of the target model (required).
- `inverse_name`: Name of the Many2one field in target model (required).

### Many2many
Bi-directional relationship between multiple records.
- `comodel_name`: Name of the target model (required).
- `relation`: Table name for the relation (optional).
- `column1`: Column name for current model in relation table.
- `column2`: Column name for target model in relation table.

## Computed Fields
```python
name = fields.Char(compute='_compute_name', store=True, readonly=False)

@api.depends('field_a', 'field_b')
def _compute_name(self):
    for record in self:
        record.name = f"{record.field_a} {record.field_b}"
```

## Selection Field Reference
```python
priority = fields.Selection([
    ('0', 'Low'),
    ('1', 'Normal'),
    ('2', 'High'),
], string="Priority", default='1')
```
