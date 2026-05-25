---
title: Odoo 19 — Fields Reference
domain: fields
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Fields Reference

## Common Parameters (kwargs)

| Parameter | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| `string` | `str` | Label shown in views. | capitalized name |
| `help` | `str` | Tooltip for the field. | `None` |
| `readonly` | `str/bool` | Expression or boolean for read-only. | `False` |
| `required` | `str/bool` | Expression or boolean for required. | `False` |
| `index` | `bool` | Create a database index. | `False` |
| `default` | `any/fn` | Default value or function. | `None` |
| `groups` | `str` | XML IDs of groups for access control. | `None` |
| `copy` | `bool` | Field value is copied on `copy()`. | `True` |
| `translate` | `bool` | Enables multi-language support. | `False` |
| `tracking` | `bool/int` | Log changes in chatter. | `False` |

## Type Hints in Odoo 19
In Odoo 19, type hints are strongly recommended on **method signatures**, not on field declarations. Field declarations remain unchanged — using variable annotations (`name: str = fields.Char(...)`) is not Odoo convention and can mislead static analyzers.

```python
# CORRECT — type hints on method signatures only
class MyModel(models.Model):
    _name = 'my.model'

    name = fields.Char(string="Name", required=True)       # No annotation on fields
    amount = fields.Float(string="Amount", digits=(16, 2))
    is_active = fields.Boolean(string="Active", default=True)
    date_start = fields.Date(string="Start Date")

    def action_confirm(self) -> bool:                       # Annotate method return type
        for rec in self:
            rec.state = 'done'
        return True

    @api.model_create_multi
    def create(self, vals_list: list[dict]) -> 'MyModel':   # Annotate params + return
        return super().create(vals_list)
```

## Simple Field Types

| Type | SQL Type | Notes |
| :--- | :--- | :--- |
| `Boolean` | `BOOL` | |
| `Integer` | `INT4` | |
| `Float` | `NUMERIC` | Use `digits=(precision, scale)` |
| `Monetary` | `NUMERIC` | Requires `currency_field` (e.g. `currency_id`) |
| `Char` | `VARCHAR` | Max length via `size` |
| `Text` | `TEXT` | Multi-line text |
| `Html` | `TEXT` | Sanitized HTML content |
| `Date` | `DATE` | Python `date` object |
| `Datetime` | `TIMESTAMP` | Python `datetime` (Stored in UTC) |
| `Selection` | `VARCHAR` | `selection=[('key', 'Label')]` |

## Relational Field Types

### Many2one
```python
partner_id: 'ResPartner' = fields.Many2one(
    comodel_name='res.partner',
    string='Partner',
    ondelete='restrict',
    check_company=True
)
```

### One2many
```python
line_ids: 'MyModelLine' = fields.One2many(
    comodel_name='my.model.line',
    inverse_name='parent_id',
    string='Lines'
)
```

### Many2many
```python
tag_ids: 'MyTag' = fields.Many2many(
    comodel_name='my.tag',
    relation='my_model_tag_rel', # Optional
    column1='model_id',
    column2='tag_id',
    string='Tags'
)
```

## New Domain Operators
Odoo 19 introduces `any!` for more efficient filtering in relational fields.
- `any!`: Stronger existence check in One2many/Many2many domains.

## Computed Fields
```python
total: float = fields.Float(compute='_compute_total', store=True, readonly=False)

@api.depends('line_ids.price_subtotal')
def _compute_total(self):
    for record in self:
        record.total = sum(record.line_ids.mapped('price_subtotal'))
```
