---
title: Odoo 14 — Module Generator
domain: scaffold
version: 14.0
edition: community
source: legacy
status: active
---

# Odoo 14 — Module Generator

## Module Structure
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
│   └── description/
│   └── src/ (JS/CSS for v14)
└── views/
```

## __manifest__.py
Odoo 14 does not use the `assets` key for JS/CSS; they are included in `data` or `qweb` sections or registered via templates.

```python
# -*- coding: utf-8 -*-
{
    'name': 'Module for Odoo 14',
    'version': '14.0.1.0.0',
    'category': 'Sales',
    'summary': 'Module summary for v14',
    'author': 'Your Company',
    'license': 'LGPL-3',
    'depends': ['base', 'mail'],
    'data': [
        'security/security.xml',
        'security/ir.model.access.csv',
        'views/assets.xml',  # Standard place to register JS/CSS in v14
        'views/my_model_views.xml',
    ],
    'qweb': [
        'static/src/xml/my_template.xml',
    ],
    'installable': True,
    'application': False,
}
```

## Registering Assets (v14 style)
In Odoo 14, assets are registered by inheriting from `web.assets_backend`.

```xml
<!-- views/assets.xml -->
<template id="assets_backend" inherit_id="web.assets_backend">
    <xpath expr="." position="inside">
        <script type="text/javascript" src="/my_module/static/src/js/my_script.js"></script>
        <link rel="stylesheet" type="text/scss" href="/my_module/static/src/scss/my_style.scss"/>
    </xpath>
</template>
```

## Model Template
```python
# -*- coding: utf-8 -*-
from odoo import api, fields, models, _

class MyModel(models.Model):
    _name = 'my.model'
    _inherit = ['mail.thread']

    name = fields.Char(string='Name', required=True, track_visibility='onchange')
    state = fields.Selection([
        ('draft', 'Draft'),
        ('done', 'Done'),
    ], default='draft', track_visibility='always')

    @api.model
    def create(self, vals):
        # Single record creation is the v14 standard
        return super(MyModel, self).create(vals)

    @api.multi
    def action_confirm(self):
        for record in self:
            record.state = 'done'
```

## View Template (attrs)
```xml
<record id="my_model_view_form" model="ir.ui.view">
    <field name="name">my.model.form</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <form>
            <header>
                <button name="action_confirm" string="Confirm" type="object"
                        attrs="{'invisible': [('state', '!=', 'draft')]}"/>
                <field name="state" widget="statusbar"/>
            </header>
            <sheet>
                <field name="name"/>
            </sheet>
            <div class="oe_chatter">
                <field name="message_follower_ids" widget="mail_followers"/>
                <field name="message_ids" widget="mail_thread"/>
            </div>
        </form>
    </field>
</record>
```
