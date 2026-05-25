---
title: Odoo 19 — Model Patterns
domain: models
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Model Patterns

## Purpose
ORM model patterns and field types for Odoo 19 including new constraint syntax, mandatory type hints, and SQL() builder usage.

## Type Hints on Method Signatures (Python 3.12+)
In Odoo 19, Python type hinting is strongly recommended on **method signatures**. Field declarations do NOT use variable annotations — the ORM descriptor pattern (`name = fields.Char(...)`) is always the correct form.

```python
from typing import Optional, Any
from odoo import models, fields, api

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model'
    _check_company_auto = True
    
    name = fields.Char(required=True)
    active = fields.Boolean(default=True)
    amount = fields.Float()
    state = fields.Selection([
        ('draft', 'Draft'),
        ('done', 'Done'),
    ], default='draft')
    company_id = fields.Many2one('res.company', required=True, default=lambda self: self.env.company)
    
    def action_confirm(self) -> bool:
        """Confirm records."""
        for record in self:
            record.state = 'done'
        return True
        
    @api.model
    def search_drafts(self, limit: int = 100) -> 'MyModel':
        return self.search([('state', '=', 'draft')], limit=limit)
```

## Mandatory SQL() Builder
String-based SQL execution is strictly forbidden in v19. All `self.env.cr.execute` calls MUST use the `SQL` object from `odoo.tools`.

```python
from odoo.tools import SQL

# CORRECT (v19)
def get_totals(self) -> float:
    self.env.cr.execute(SQL(
        "SELECT SUM(amount) FROM my_model WHERE state = %s",
        'done'
    ))
    result = self.env.cr.fetchone()
    return result[0] if result else 0.0
```

## New Constraints API
The old `_sql_constraints` list is deprecated. Odoo 19 models use the new `models.Constraint()` class attributes.

```python
class MyModel(models.Model):
    _name = 'my.model'

    code = fields.Char()
    amount = fields.Float()

    # Unique constraint
    _code_unique = models.Constraint(
        'UNIQUE(code)',
        'Code must be unique.',
    )

    # Check constraint
    _amount_positive = models.Constraint(
        'CHECK(amount >= 0)',
        'Amount must be positive.',
    )
```

## Multi-Company Enforcement
`_check_company_auto = True` is strongly enforced. All relational fields crossing company boundaries must explicitly use `check_company=True`.
