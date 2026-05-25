---
title: Odoo 15 — Module Generator
domain: scaffold
version: 15.0
edition: community
source: legacy
status: active
---

# Odoo 15 — Module Generator

## Module Scaffolding Structure
A standard Odoo 15 module structure follows this layout:
```text
my_module/
├── __init__.py
├── __manifest__.py
├── controllers/
├── data/
├── models/
├── security/
│   ├── ir.model.access.csv
│   └── security.xml
├── static/
│   └── src/
│       ├── js/
│       ├── scss/
│       └── xml/
└── views/
```

## __manifest__.py Template
In Odoo 15, JS/CSS/XML assets are managed via the `assets` key in the manifest.

```python
# -*- coding: utf-8 -*-
{
    'name': 'Custom Module Title',
    'version': '15.0.1.0.0',
    'category': 'Sales',
    'summary': 'Short module summary',
    'author': 'Your Company',
    'license': 'LGPL-3',
    'depends': ['base', 'mail'],
    'data': [
        'security/security.xml',
        'security/ir.model.access.csv',
        'views/my_model_views.xml',
        'views/menus.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'my_module/static/src/js/**/*.js',
            'my_module/static/src/xml/**/*.xml',
            'my_module/static/src/scss/**/*.scss',
        ],
    },
    'installable': True,
    'application': False,
}
```

## Model Template
Odoo 15 removed the `@api.multi` and `@api.one` decorators. Methods work on recordsets by default.

```python
# -*- coding: utf-8 -*-
from odoo import api, fields, models, _

class MyModel(models.Model):
    _name = 'my.module.model'
    _description = 'My Model Description'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    name = fields.Char(string='Name', required=True, tracking=True)
    active = fields.Boolean(default=True)
    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('done', 'Done'),
    ], string='Status', default='draft', tracking=True)

    partner_id = fields.Many2one('res.partner', string='Partner', tracking=True)
    company_id = fields.Many2one('res.company', default=lambda self: self.env.company)

    # Computed field
    total_amount = fields.Float(compute='_compute_total_amount', store=True)

    @api.depends('line_ids.amount')
    def _compute_total_amount(self):
        for record in self:
            record.total_amount = sum(record.line_ids.mapped('amount'))

    # CRUD Overrides (Batch create recommended)
    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if not vals.get('name'):
                vals['name'] = self.env['ir.sequence'].next_by_code('my.model') or _('New')
        return super().create(vals_list)
```

## x2many Operations
Odoo 15 still uses the tuple syntax for x2many operations (the `Command` class was introduced in v16).

```python
# Examples of x2many commands in v15:
self.write({
    'line_ids': [
        (0, 0, {'name': 'New Line'}),       # Create
        (1, line_id, {'name': 'Updated'}),  # Update
        (2, line_id),                       # Delete
        (4, line_id),                       # Link
        (5, 0, 0),                          # Clear
        (6, 0, [id1, id2]),                 # Set
    ]
})
```

## Checklist for v15 Generation
- [ ] Use `tracking=True` instead of `track_visibility`.
- [ ] No `@api.multi` decorators.
- [ ] Use `assets` key in manifest for frontend resources.
- [ ] Use `attrs` in XML views for visibility/readonly logic.
- [ ] Python 3.8+ compatibility.
