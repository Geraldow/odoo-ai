---
title: Odoo 19 — New Constraint Syntax
domain: models
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — New Constraint Syntax

## Purpose
New SQL constraint patterns in Odoo 19. The traditional `_sql_constraints` list is replaced by the `models.Constraint()` class API (defined in `odoo.orm.table_objects`).

## models.Constraint() Class

In Odoo 19, SQL constraints are defined as class attributes using `models.Constraint`.

### Syntax

```python
from odoo import models, fields

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model'

    code = fields.Char()
    amount = fields.Float()
    company_id = fields.Many2one('res.company')

    # Replaces the old ('code_unique', 'UNIQUE(code)', '...') syntax
    _code_unique = models.Constraint(
        'UNIQUE(code)',
        'Code must be unique.',
    )

    _code_company_unique = models.Constraint(
        'UNIQUE(code, company_id)',
        'Code must be unique per company.',
    )

    _amount_positive = models.Constraint(
        'CHECK(amount >= 0)',
        'Amount must be positive.',
    )
```

## Migration from v18

**Old v18 (Deprecated):**
```python
_sql_constraints = [
    ('code_unique', 'UNIQUE(code)', 'Code must be unique.'),
    ('amount_positive', 'CHECK(amount >= 0)', 'Amount must be positive.'),
]
```

**New v19 (Required):**
```python
_code_unique = models.Constraint(
    'UNIQUE(code)',
    'Code must be unique.',
)
_amount_positive = models.Constraint(
    'CHECK(amount >= 0)',
    'Amount must be positive.',
)
```

### Python Constraints
Python constraints via `@api.constrains` remain largely unchanged from v18, but you must ensure Python 3.12 compatibility and type hints in your methods.
