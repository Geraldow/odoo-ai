---
title: Odoo 17 — Model Patterns
domain: models
version: 17.0
edition: community
source: legacy
status: active
---

# Odoo 17 — Model Patterns

## Version-Specific Patterns

### Key Characteristics
| Feature | Odoo 17.0 Pattern |
|---------|-------------------|
| attrs in views | **REMOVED** - must use conditional attributes |
| Create method | `@api.model_create_multi` **MANDATORY** |
| X2many commands | `Command` class (recommended) |
| Change tracking | `tracking=True` |
| OWL | Version 2.x (enhanced) |
| Python version | 3.10+ |

## BREAKING: attrs Removed

```xml
<!-- THIS WILL BREAK IN v17 -->
<field name="partner_id"
       attrs="{'invisible': [('state', '=', 'draft')]}"/>

<!-- v17 REQUIRED syntax -->
<field name="partner_id"
       invisible="state == 'draft'"/>
```

## BREAKING: create_multi Mandatory

```python
# v16 (optional):
@api.model
def create(self, vals):
    return super().create(vals)

# v17 (MANDATORY):
@api.model_create_multi
def create(self, vals_list):
    return super().create(vals_list)
```

## Model Definition

```python
from odoo import models, fields, api, _
from odoo.fields import Command
from odoo.exceptions import UserError, ValidationError
import logging

_logger = logging.getLogger(__name__)

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'sequence, id desc'

    name = fields.Char(
        string='Name',
        required=True,
        index='trigram',  # v17: index type specification
        tracking=True,
    )

    code = fields.Char(
        index=True,
        copy=False,
    )

    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('in_progress', 'In Progress'),
        ('done', 'Done'),
        ('cancelled', 'Cancelled'),
    ], default='draft', tracking=True, index=True)

    priority = fields.Selection([
        ('0', 'Normal'),
        ('1', 'Low'),
        ('2', 'High'),
        ('3', 'Very High'),
    ], default='0', index=True)

    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)

    # Date fields
    date = fields.Date(default=fields.Date.context_today)
    date_deadline = fields.Date(index=True)

    # Relational fields
    company_id = fields.Many2one(
        'res.company',
        required=True,
        default=lambda self: self.env.company,
        index=True,
    )

    user_id = fields.Many2one(
        'res.users',
        default=lambda self: self.env.user,
        tracking=True,
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

    line_count = fields.Integer(
        compute='_compute_line_count',
    )

    currency_id = fields.Many2one(
        'res.currency',
        related='company_id.currency_id',
    )

    # Binary and HTML fields
    attachment = fields.Binary(attachment=True)
    description = fields.Html(sanitize=True)
    note = fields.Text()
```

## CRUD Methods (v17 Patterns)

```python
@api.model_create_multi
def create(self, vals_list):
    """MANDATORY: @api.model_create_multi in v17"""
    for vals in vals_list:
        if not vals.get('code'):
            vals['code'] = self.env['ir.sequence'].next_by_code('my.model')
        if 'company_id' not in vals:
            vals['company_id'] = self.env.company.id

    records = super().create(vals_list)

    # Post-creation logic
    for record in records:
        record.message_post(body=_("Record created."))

    return records

def write(self, vals):
    """Write with state validation"""
    if 'state' in vals:
        if vals['state'] == 'confirmed':
            for record in self:
                if not record.line_ids:
                    raise UserError(
                        _("Record '%s' must have at least one line.") % record.name
                    )

    result = super().write(vals)

    # Track specific field changes
    if 'partner_id' in vals:
        self._log_partner_change()

    return result

def unlink(self):
    """Delete with state check"""
    for record in self:
        if record.state not in ('draft', 'cancelled'):
            raise UserError(
                _("Cannot delete '%s' (state: %s). Only draft or cancelled records can be deleted.")
                % (record.name, record.state)
            )
    return super().unlink()

def copy(self, default=None):
    """Copy with name suffix"""
    self.ensure_one()
    default = dict(default or {})
    if 'name' not in default:
        default['name'] = _("%s (copy)", self.name)
    default['state'] = 'draft'
    return super().copy(default)
```

## Computed Fields

```python
@api.depends('line_ids.amount')
def _compute_total(self):
    for record in self:
        record.total_amount = sum(record.line_ids.mapped('amount'))

@api.depends('line_ids')
def _compute_line_count(self):
    for record in self:
        record.line_count = len(record.line_ids)

# Computed with conditional logic
is_overdue = fields.Boolean(
    compute='_compute_is_overdue',
    search='_search_is_overdue',
    store=True,
)

@api.depends('date_deadline', 'state')
def _compute_is_overdue(self):
    today = fields.Date.context_today(self)
    for record in self:
        record.is_overdue = (
            record.date_deadline
            and record.date_deadline < today
            and record.state not in ('done', 'cancelled')
        )

def _search_is_overdue(self, operator, value):
    today = fields.Date.context_today(self)
    if (operator == '=' and value) or (operator == '!=' and not value):
        return [
            ('date_deadline', '<', today),
            ('state', 'not in', ('done', 'cancelled')),
        ]
    return ['|', ('date_deadline', '>=', today), ('date_deadline', '=', False)]
```

## Action Methods

```python
def action_confirm(self):
    """Confirm records - validate before state change"""
    for record in self.filtered(lambda r: r.state == 'draft'):
        if not record.line_ids:
            raise UserError(_("Add at least one line to confirm '%s'.") % record.name)
    self.filtered(lambda r: r.state == 'draft').write({'state': 'confirmed'})

def action_start(self):
    """Start work on records"""
    self.filtered(lambda r: r.state == 'confirmed').write({'state': 'in_progress'})

def action_done(self):
    """Mark records as done"""
    self.filtered(lambda r: r.state == 'in_progress').write({'state': 'done'})

def action_cancel(self):
    """Cancel records"""
    self.filtered(lambda r: r.state not in ('done', 'cancelled')).write({'state': 'cancelled'})

def action_draft(self):
    """Reset to draft"""
    self.filtered(lambda r: r.state == 'cancelled').write({'state': 'draft'})

def action_view_lines(self):
    """View lines action"""
    self.ensure_one()
    return {
        'type': 'ir.actions.act_window',
        'name': _('Lines'),
        'res_model': 'my.model.line',
        'view_mode': 'tree,form',
        'domain': [('model_id', '=', self.id)],
        'context': {'default_model_id': self.id},
    }
```

## v17 Best Practices

1. **NO attrs** - Always use Python expression attributes
2. **@api.model_create_multi** - Always use for create methods
3. **Use Command class** - For all x2many operations
4. **Index important fields** - Use `index=True` or `index='trigram'`
5. **Type-aware filtering** - Use `filtered()` with lambdas
