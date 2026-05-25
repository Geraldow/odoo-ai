---
title: Odoo 17 — Version Notes
domain: changelog
version: 17.0
edition: community
source: legacy
status: active
---

# Odoo 17 — Version Notes

## Version Overview

| Aspect | Details |
|--------|---------|
| Release Date | October 2023 |
| Python | 3.10, 3.11 |
| PostgreSQL | 13, 14, 15 |
| Frontend | OWL 2.x (enhanced) |

## BREAKING Changes from v16

### attrs REMOVED
The `attrs` attribute is completely removed from views.

```xml
<!-- v16 (BREAKS in v17) -->
<field name="partner_id" attrs="{'invisible': [('state', '=', 'draft')]}"/>

<!-- v17 REQUIRED -->
<field name="partner_id" invisible="state == 'draft'"/>
```

### @api.model_create_multi MANDATORY
The `create` method must now always use the batch decorator.

```python
# v17 REQUIRED
@api.model_create_multi
def create(self, vals_list):
    return super().create(vals_list)
```

## Key Features

- **Improved UI/UX**: Search bar improvements, new "milk" theme.
- **Performance**: Faster view rendering and reduced server response times.
- **WhatsApp Integration**: Native integration for Enterprise.
- **New Search View**: Advanced filtering and search panel improvements.

## Migration Steps

1. **Convert attrs**: Use Python expression syntax for `invisible`, `readonly`, and `required`.
2. **Update create methods**: Ensure all `create` overrides use `@api.model_create_multi`.
3. **Command Class**: Prefer `Command` class for all x2many operations.
4. **Python 3.10+**: Ensure the environment uses a compatible Python version.

## Expression Syntax Conversion

| v16 Domain | v17 Expression |
|------------|----------------|
| `[('state', '=', 'draft')]` | `state == 'draft'` |
| `['|', A, B]` | `A or B` |
| `['&', A, B]` | `A and B` |
| `[('field', '=', False)]` | `not field` |
| `[('field', 'in', ['a', 'b'])]` | `field in ('a', 'b')` |
