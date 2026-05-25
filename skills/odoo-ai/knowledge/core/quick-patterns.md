---
title: Quick Patterns Cheat Sheet
domain: core
version: all
edition: both
source: fhidalgo
status: active
---

# Quick Patterns Cheat Sheet

## Purpose
80% use-cases in one page: models, fields, computes, views, and security.

## Model Scaffolding (v18)
```python
from odoo import api, fields, models, Command, _

class MyModel(models.Model):
    _name = 'my_module.my_model'
    _description = 'My Model'
    _inherit = ['mail.thread']
    _check_company_auto = True
```

## Fields Snippets
```python
# Basic
name = fields.Char(required=True, tracking=True)
active = fields.Boolean(default=True)
state = fields.Selection([('draft', 'Draft'), ('done', 'Done')], default='draft')
date = fields.Date(default=fields.Date.context_today)

# Relational
partner_id = fields.Many2one('res.partner', check_company=True)
tag_ids = fields.Many2many('res.partner.category', string='Tags')
line_ids = fields.One2many('my_module.line', 'parent_id', string='Lines')

# Monetary
currency_id = fields.Many2one('res.currency', default=lambda self: self.env.company.currency_id)
amount = fields.Monetary(currency_field='currency_id')
```

## Compute & Constrains
```python
total = fields.Float(compute='_compute_total', store=True)

@api.depends('line_ids.price_subtotal')
def _compute_total(self):
    for rec in self:
        rec.total = sum(rec.line_ids.mapped('price_subtotal'))

@api.constrains('amount')
def _check_amount(self):
    for rec in self:
        if rec.amount < 0:
            raise ValidationError(_("Amount cannot be negative."))
```

## CRUD Overrides
```python
@api.model_create_multi
def create(self, vals_list):
    # logic before create
    return super().create(vals_list)

def write(self, vals):
    # logic before write
    return super().write(vals)
```

## XML View Snippets (v17/v18)
```xml
<!-- Form Header -->
<header>
    <button name="action_done" type="object" string="Mark Done" 
            class="btn-primary" invisible="state == 'done'"/>
    <field name="state" widget="statusbar"/>
</header>

<!-- List Decoration -->
<tree decoration-info="state == 'draft'" decoration-success="state == 'done'">
    <field name="name"/>
    <field name="state" widget="badge"/>
</tree>

<!-- Search Filters -->
<search>
    <field name="name"/>
    <filter name="my_records" string="My Records" domain="[('user_id', '=', uid)]"/>
    <group expand="0" string="Group By">
        <filter name="group_state" context="{'group_by': 'state'}"/>
    </group>
</search>
```

## Security (CSV)
```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_my_model_user,my.model.user,model_my_module_my_model,base.group_user,1,1,1,0
```

## Manifest (v18)
```python
{
    'name': 'My Module',
    'version': '18.0.1.0.0',
    'depends': ['base', 'mail'],
    'data': [
        'security/ir.model.access.csv',
        'views/my_model_views.xml',
    ],
    'license': 'LGPL-3',
}
```

## Python Snippets
- **Search**: `records = self.env['my.model'].search([('state', '=', 'draft')])`
- **Browse**: `record = self.env['my.model'].browse(some_id)`
- **Sudo**: `record.sudo().write({'state': 'done'})`
- **Context**: `record.with_context(lang='es_PE').read(['name'])`
- **Ensure One**: `self.ensure_one()`
- **Command**: `rec.write({'line_ids': [Command.create({'name': 'New Line'})]})`
