---
title: ORM Patterns
domain: core
version: all
edition: both
source: fhidalgo+unclecatvn
status: active
---

# ORM Patterns

## Purpose
Core patterns for interacting with the Odoo ORM, including recordset operations, environment management, and CRUD methods.

## The Environment (`self.env`)
The environment provides access to the database cursor, the current user, and all Odoo models.

- `self.env.user`: The current user record.
- `self.env.company`: The current active company.
- `self.env.companies`: All allowed companies for the user.
- `self.env['model.name']`: Returns an empty recordset for the specified model.
- `self.env.cr`: The database cursor for raw SQL.

## Recordset Operations

### Searching and Browsing
```python
# Search returns a recordset matching the domain
records = self.env['res.partner'].search([('is_company', '=', True)], limit=10)

# Search count returns the number of records matching the domain
count = self.env['res.partner'].search_count([('active', '=', True)])

# Browse returns a recordset for specific IDs (no DB query until field access)
records = self.env['res.partner'].browse([1, 2, 3])
```

### Filtering, Mapping, and Sorting
```python
# Filter records in memory
draft_records = records.filtered(lambda r: r.state == 'draft')

# Map values into a list or recordset
names = records.mapped('name')
partner_ids = records.mapped('partner_id')

# Sort recordset
sorted_records = records.sorted(key=lambda r: r.create_date, reverse=True)
```

## Record Manipulation (CRUD)

### Create (Multi-create pattern)
Always use `@api.model_create_multi` for efficiency.
```python
@api.model_create_multi
def create(self, vals_list):
    # vals_list is a list of dictionaries
    return super().create(vals_list)
```

### Write and Unlink
```python
# Write updates all records in the recordset
records.write({'state': 'done'})

# Unlink deletes all records in the recordset
records.unlink()
```

## Altering the Environment

### Sudo and Context
```python
# Bypass security rules (use with caution)
records_sudo = self.env['res.partner'].sudo().search([])

# Change context (e.g., language, timezone)
records_fr = self.with_context(lang='fr_FR').browse(ids)

# Change active company or user
records_comp2 = self.with_company(company_id).search([])
records_as_admin = self.with_user(admin_id).search([])
```

## Decorator Quick Reference

| Decorator | Usage |
|-----------|-------|
| `@api.model` | Method called on the model class (no recordset). |
| `@api.depends` | Defines dependencies for a computed field. |
| `@api.constrains` | Python-level validation check. |
| `@api.onchange` | UI-level dynamic update (non-persistent). |
| `@api.depends_context` | Recompute when context keys change. |

## ORM Performance Best Practices
- **Use `mapped()`** to avoid loops for extracting simple fields.
- **Use `filtered()`** instead of searching again if you already have the records.
- **Minimize `sudo()`**; always check if you can use specific groups or record rules instead.
- **Batch your updates**; calling `write()` on a recordset is faster than calling it in a loop.
- **Use `Command`** for X2many fields to avoid unnecessary reads/writes.

## AI Agent Instructions
1. **Prefer** recordset operations (`mapped`, `filtered`) over Python list comprehensions for Odoo models.
2. **Always** implement `create` using the `@api.model_create_multi` decorator.
3. **Use** `ensure_one()` when a method expects exactly one record.
4. **Avoid** raw SQL unless the ORM cannot handle the complexity or performance requirement.
5. **Always** use `with_context` when passing transient state through method calls.
