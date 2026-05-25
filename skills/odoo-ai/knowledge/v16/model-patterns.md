---
title: Odoo 16 — Model Patterns
domain: models
version: 16.0
edition: community
source: legacy
status: active
---

# Odoo 16 — Model Patterns

## Purpose
ORM model patterns and field types for Odoo 16.

## Version-Specific Patterns

### Key Characteristics
| Feature | Odoo 16.0 Pattern |
|---------|-------------------|
| X2many commands | `Command` class (tuple syntax still works) |
| attrs in views | DEPRECATED - use conditional attributes |
| Change tracking | `tracking=True` |
| OWL | Version 2.x |
| Python version | 3.8+ |

## New in v16: Command Class

```python
from odoo.fields import Command

# Command class methods
Command.create(values)      # Replaces (0, 0, values)
Command.update(id, values)  # Replaces (1, id, values)
Command.delete(id)          # Replaces (2, id, 0)
Command.unlink(id)          # Replaces (3, id, 0) - M2M only
Command.link(id)            # Replaces (4, id, 0)
Command.clear()             # Replaces (5, 0, 0)
Command.set(ids)            # Replaces (6, 0, ids)
```

## Model Definition

```python
from odoo import models, fields, api, _
from odoo.fields import Command
from odoo.exceptions import UserError, ValidationError

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'sequence, name'

    name = fields.Char(
        string='Name',
        required=True,
        index=True,
        tracking=True,
    )

    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('done', 'Done'),
        ('cancelled', 'Cancelled'),
    ], default='draft', tracking=True, index=True)

    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)

    # Date fields
    date = fields.Date(default=fields.Date.context_today)
    date_deadline = fields.Date()

    # Relational fields
    company_id = fields.Many2one(
        'res.company',
        required=True,
        default=lambda self: self.env.company,
    )

    partner_id = fields.Many2one(
        'res.partner',
        domain="[('company_id', 'in', [company_id, False])]",
        tracking=True,
    )

    line_ids = fields.One2many(
        'my.model.line',
        'model_id',
        copy=True,
    )

    tag_ids = fields.Many2many('my.model.tag')

    # Computed fields
    total_amount = fields.Monetary(
        compute='_compute_total',
        store=True,
        currency_field='currency_id',
    )

    currency_id = fields.Many2one(
        'res.currency',
        related='company_id.currency_id',
    )
```

## Using Command Class

```python
def create_with_lines(self):
    """Create record with lines using Command class"""
    return self.env['my.model'].create({
        'name': 'New Record',
        'line_ids': [
            Command.create({'name': 'Line 1', 'quantity': 1, 'price': 10.0}),
            Command.create({'name': 'Line 2', 'quantity': 2, 'price': 20.0}),
        ],
    })

def update_lines(self):
    """Update one2many lines"""
    self.write({
        'line_ids': [
            Command.update(self.line_ids[0].id, {'quantity': 5}),
            Command.create({'name': 'New Line', 'quantity': 1}),
            Command.delete(self.line_ids[-1].id),
        ],
    })

def manage_tags(self):
    """Manage many2many using Command class"""
    tag = self.env['my.model.tag'].create({'name': 'Important'})

    # Link existing tag
    self.write({'tag_ids': [Command.link(tag.id)]})

    # Replace all tags
    self.write({'tag_ids': [Command.set([tag.id])]})

    # Clear all tags
    self.write({'tag_ids': [Command.clear()]})

    # Unlink specific tag
    self.write({'tag_ids': [Command.unlink(tag.id)]})
```

## CRUD Methods

```python
@api.model_create_multi
def create(self, vals_list):
    """Batch create - recommended in v16"""
    for vals in vals_list:
        if not vals.get('code'):
            vals['code'] = self.env['ir.sequence'].next_by_code('my.model')
    return super().create(vals_list)

def write(self, vals):
    """Multi-record write with Command awareness"""
    result = super().write(vals)
    if 'state' in vals and vals['state'] == 'confirmed':
        for record in self:
            record.message_post(body=_("Record confirmed."))
    return result

def unlink(self):
    """Delete with validation"""
    if any(r.state not in ('draft', 'cancelled') for r in self):
        raise UserError(_("Only draft or cancelled records can be deleted."))
    return super().unlink()
```

## XML Views: attrs Deprecation

```xml
<!--
    v16: attrs is DEPRECATED
    Start migrating to conditional attributes
-->

<!-- OLD (deprecated but still works in v16) -->
<field name="partner_id"
       attrs="{'invisible': [('state', '=', 'draft')],
               'required': [('state', '=', 'confirmed')],
               'readonly': [('state', '=', 'done')]}"/>

<!-- NEW (v16+ recommended) -->
<field name="partner_id"
       invisible="state == 'draft'"
       required="state == 'confirmed'"
       readonly="state == 'done'"/>
```

## Computed Fields

```python
@api.depends('line_ids.amount')
def _compute_total(self):
    for record in self:
        record.total_amount = sum(record.line_ids.mapped('amount'))

# With currency
@api.depends('line_ids.price_subtotal', 'currency_id')
def _compute_amount_total(self):
    for record in self:
        record.amount_total = sum(record.line_ids.mapped('price_subtotal'))
```

## v16 Best Practices

1. **Use Command class** for x2many operations
2. **Migrate from attrs** to conditional attributes
3. **Use @api.model_create_multi** for create methods
4. **Leverage OWL 2.x** for frontend components
5. **Use index=True** on frequently searched fields
