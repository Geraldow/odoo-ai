---
title: Odoo 15 — Model Patterns
domain: models
version: 15.0
edition: community
source: legacy
status: active
---

# Odoo 15 — Model Patterns

## Purpose
ORM model patterns and field types for Odoo 15.

## Version-Specific Patterns

### Key Characteristics
| Feature | Odoo 15.0 Pattern |
|---------|-------------------|
| Multi-record decorator | REMOVED - methods iterate by default |
| Change tracking | `tracking=True` (track_visibility deprecated) |
| X2many commands | Tuple syntax `(0, 0, vals)` |
| attrs in views | Full support |
| OWL | Version 1.x introduced |
| Python version | 3.7+ |

## Model Definition

```python
from odoo import models, fields, api, _
from odoo.exceptions import UserError, ValidationError

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    name = fields.Char(string='Name', required=True, tracking=True)
    state = fields.Selection([
        ('draft', 'Draft'),
        ('done', 'Done'),
    ], default='draft', tracking=True)

    company_id = fields.Many2one('res.company', default=lambda self: self.env.company)
    partner_id = fields.Many2one('res.partner')
    line_ids = fields.One2many('my.model.line', 'model_id')

    @api.depends('line_ids.amount')
    def _compute_total(self):
        for record in self:
            record.total_amount = sum(record.line_ids.mapped('amount'))
```

## CRUD Methods (v15)

```python
@api.model
def create(self, vals):
    """Single record create - standard in v15"""
    return super().create(vals)

def write(self, vals):
    """Multi-record write - methods iterate by default"""
    return super().write(vals)
```

## X2many Operations (Tuple Syntax)

```python
def create_with_lines(self):
    return self.env['my.model'].create({
        'name': 'New Record',
        'line_ids': [
            (0, 0, {'name': 'Line 1'}),
            (0, 0, {'name': 'Line 2'}),
        ],
    })
```

## Migration Notes to v16

- **Command class available in v16** - Can use `Command.create()` instead of tuples.
- **attrs deprecation begins in v16**.
- **OWL 2.x in v16** - Major frontend update.
