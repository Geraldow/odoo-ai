---
title: Odoo 14 — Model Patterns
domain: models
version: 14.0
edition: community
source: legacy
status: active
---

# Odoo 14 — Model Patterns

## Standard Model Definition
Odoo 14 is the last version where `@api.multi` and `track_visibility` were standard (though already being discouraged in favor of v15 patterns).

```python
# -*- coding: utf-8 -*-
from odoo import api, fields, models, _
from odoo.exceptions import UserError, ValidationError

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model Description'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'name desc'

    name = fields.Char(
        string='Name', 
        required=True, 
        track_visibility='onchange'  # v14 standard
    )
    active = fields.Boolean(default=True)
    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('done', 'Done'),
    ], string='Status', default='draft', track_visibility='always')

    partner_id = fields.Many2one('res.partner', string='Partner')
    user_id = fields.Many2one('res.users', string='Responsible', default=lambda self: self.env.user)
    company_id = fields.Many2one('res.company', string='Company', default=lambda self: self.env.company)
    
    line_ids = fields.One2many('my.model.line', 'parent_id', string='Lines')

    # Computed Field (stored)
    total_amount = fields.Float(compute='_compute_total_amount', store=True)

    @api.depends('line_ids.amount')
    def _compute_total_amount(self):
        for record in self:
            record.total_amount = sum(record.line_ids.mapped('amount'))

    # v14 Action Method (using @api.multi)
    @api.multi
    def action_confirm(self):
        for record in self:
            if record.state != 'draft':
                raise UserError(_("Only draft records can be confirmed."))
            record.state = 'confirmed'
        return True
```

## CRUD Operations in v14
In Odoo 14, single-record creation was the standard pattern.

```python
@api.model
def create(self, vals):
    if not vals.get('name'):
        vals['name'] = self.env['ir.sequence'].next_by_code('my.model') or _('New')
    return super(MyModel, self).create(vals)

@api.multi
def write(self, vals):
    # logic here
    return super(MyModel, self).write(vals)

@api.multi
def unlink(self):
    for record in self:
        if record.state == 'done':
            raise UserError(_("Cannot delete a record in 'Done' state."))
    return super(MyModel, self).unlink()
```

## Relationship Commands (Tuples)
Relationship fields are modified using command tuples.

| Command | Tuple | Purpose |
|---------|-------|---------|
| Create | `(0, 0, vals)` | Add a new record |
| Update | `(1, id, vals)` | Update existing record |
| Delete | `(2, id, 0)` | Remove and delete record |
| Unlink | `(3, id, 0)` | Remove link (don't delete) |
| Link | `(4, id, 0)` | Link existing record |
| Clear | `(5, 0, 0)` | Unlink all records |
| Set | `(6, 0, [ids])` | Replace all with these IDs |

## Key Differences from v15
- **Decorators**: `@api.multi` is explicitly used in v14.
- **Tracking**: `track_visibility='onchange'` or `'always'` is used instead of `tracking=True`.
- **Super**: `super(ClassName, self).method()` is common, though `super().method()` works in Python 3.
- **Scaffolding**: Focus on single-record `create` rather than `vals_list`.
