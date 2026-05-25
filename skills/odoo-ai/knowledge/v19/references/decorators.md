---
title: Odoo 19 — Decorators Reference
domain: orm
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Decorators Reference

## Core API Decorators

| Decorator | Purpose | Usage Note |
| :--- | :--- | :--- |
| `@api.model` | Method that doesn't use `ids`. | `self` is an empty recordset. |
| `@api.model_create_multi` | Performance-optimized creation. | Mandatory for custom `create` overrides. |
| `@api.depends` | Computed field dependencies. | Supports dot-notation paths. |
| `@api.onchange` | Web-client only reactive logic. | Avoid for data integrity; use `compute`. |
| `@api.constrains` | Server-side validation. | Triggers on `create` and `write`. |
| `@api.returns` | Ensures return is a recordset. | Useful for API consistency. |

## Usage with Type Hints (v19)

### `@api.model_create_multi`
```python
@api.model_create_multi
def create(self, vals_list: list[dict]) -> 'MyModel':
    for vals in vals_list:
        if not vals.get('name'):
            vals['name'] = self.env['ir.sequence'].next_by_code('my.code')
    return super().create(vals_list)
```

### `@api.depends`
```python
@api.depends('line_ids.price_total', 'tax_ids')
def _compute_amount_total(self) -> None:
    for record in self:
        record.amount_total = sum(record.line_ids.mapped('price_total'))
```

### `@api.constrains`
```python
from odoo.exceptions import ValidationError

@api.constrains('date_start', 'date_end')
def _check_dates(self) -> None:
    for record in self:
        if record.date_start > record.date_end:
            raise ValidationError("Start date must be before end date.")
```

## Special Contexts & Methods

- `self.env`: The Environment object (Registry, CR, UID, Context).
- `self.ensure_one()`: Ensures the recordset contains exactly one record.
- `self.sudo()`: Switches to Superuser (OdooBot) for the call chain.
- `self.with_context(key=value)`: Returns a new recordset with modified context.
- `self.filtered(lambda r: r.state == 'done')`: Filters the recordset in-memory.
- `self.mapped('field_name')`: Extracts field values as a list or recordset.

## Deprecations
- `odoo.osv`: Finally removed/marked as strictly obsolete. Always use `odoo.models`.
- `check_access_rights`: Replaced by the more generic `check_access` for unified permission handling.
