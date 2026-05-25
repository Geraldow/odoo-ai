---
title: Odoo 18 — Decorators Reference
domain: orm
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Decorators Reference

## Core API Decorators

| Decorator | Purpose | Context |
| :--- | :--- | :--- |
| `@api.model` | Method that doesn't use `ids`. | `self` is recordset with no IDs. |
| `@api.model_create_multi` | Batch creation for performance. | `self` is model, `vals_list` is list of dicts. |
| `@api.depends` | Computed field dependencies. | Triggers recomputation on changes. |
| `@api.onchange` | UI interaction (pseudo-reactive). | Triggers only on the web client. |
| `@api.constrains` | Python-level validation. | Prevents saving if validation fails. |
| `@api.returns` | Ensures return value is a recordset. | Wraps return in recordset of specific model. |

## Usage Examples

### `@api.model_create_multi`
Preferred way to implement `create`.
```python
@api.model_create_multi
def create(self, vals_list):
    for vals in vals_list:
        if 'name' not in vals:
            vals['name'] = 'Draft'
    return super().create(vals_list)
```

### `@api.depends`
Required for `compute` fields.
```python
@api.depends('line_ids.price_total')
def _compute_amount_total(self):
    for record in self:
        record.amount_total = sum(record.line_ids.mapped('price_total'))
```

### `@api.onchange`
Used for UI-only updates. Do not use for data integrity.
```python
@api.onchange('partner_id')
def _onchange_partner_id(self):
    if self.partner_id:
        self.email = self.partner_id.email
```

### `@api.constrains`
Used for complex validation.
```python
@api.constrains('age')
def _check_age(self):
    for record in self:
        if record.age < 18:
            raise ValidationError("Must be an adult.")
```

## Special Contexts

- `self.env`: The environment (registry, cr, uid, context).
- `self.ensure_one()`: Validates that recordset has exactly one record.
- `self.sudo()`: Switches to OdooBot (superuser) for the current call chain.
- `self.with_context(key=value)`: Returns a new recordset with updated context.
