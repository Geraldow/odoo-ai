---
title: Odoo 17 — Version Knowledge
domain: reference
version: 17.0
edition: community
source: legacy
status: active
---

# Odoo 17 — Version Knowledge

## Deprecation Reference

### Decorators
- `@api.model_create_multi`: **Required** for all create methods.
- `@api.multi`, `@api.one`: **Removed** (use standard methods).

### View Attributes
- `attrs`: **Removed** (use direct attributes).
- `states`: **Removed** (use `invisible` expression).

### x2many Operations
- Tuple commands `(0, 0, {...})`: **Deprecated** (use `Command.create({...})`).
- `Command` class: **Required** for all relational operations.

## Syntax Comparison

### Visibility
```xml
<!-- v16 -->
<field name="x" attrs="{'invisible': [('state', '=', 'draft')]}"/>

<!-- v17 -->
<field name="x" invisible="state == 'draft'"/>
```

### Create Method
```python
# v17
@api.model_create_multi
def create(self, vals_list):
    return super().create(vals_list)
```

## Record Rules (v17+)

Use `company_ids` or `allowed_company_ids` in multi-company rules.

```xml
<field name="domain_force">[('company_id', 'in', company_ids)]</field>
```

## Preparation for v18

- **_check_company_auto**: New pattern for automatic company validation.
- **check_company=True**: Field attribute for relational validation.
- **SQL() builder**: New tool for safe raw SQL execution.
- **Type hints**: Highly recommended for method signatures.

## Python Version Requirements

| Odoo Version | Python Min | Python Recommended |
|--------------|------------|-------------------|
| 16.0 | 3.8 | 3.10 |
| 17.0 | 3.10 | 3.11 |
| 18.0 | 3.11 | 3.12 |
| 19.0 | 3.12 | 3.12 |
