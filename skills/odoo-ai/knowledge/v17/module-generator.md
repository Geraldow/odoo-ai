---
title: Odoo 17 — Module Generator
domain: scaffold
version: 17.0
edition: community
source: legacy
status: active
---

# Odoo 17 — Module Generator

## Version 17.0 Requirements

- **Python**: 3.10+ required
- **Key Changes**: `attrs` REMOVED from views, `@api.model_create_multi` mandatory
- **View syntax**: Direct `invisible`/`readonly`/`required` attributes with Python expressions

## __manifest__.py Template (v17)

```python
# -*- coding: utf-8 -*-
{
    'name': 'Custom Module',
    'version': '17.0.1.0.0',
    'category': 'Tools',
    'summary': 'Short description',
    'author': 'Author Name',
    'license': 'LGPL-3',
    'depends': ['base', 'mail'],
    'data': [
        'security/module_security.xml',
        'security/ir.model.access.csv',
        'views/model_views.xml',
        'views/menuitems.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'module_name/static/src/**/*.js',
            'module_name/static/src/**/*.xml',
            'module_name/static/src/**/*.scss',
        ],
    },
    'installable': True,
    'application': False,
}
```

## Model Template (v17)

```python
# -*- coding: utf-8 -*-
from odoo import api, fields, models, Command, _
from odoo.exceptions import UserError

class CustomModel(models.Model):
    _name = 'custom.model'
    _description = 'Custom Model'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    name = fields.Char(required=True, tracking=True, index='btree')
    state = fields.Selection([
        ('draft', 'Draft'),
        ('confirmed', 'Confirmed'),
        ('done', 'Done'),
    ], default='draft', tracking=True)

    company_id = fields.Many2one('res.company', default=lambda self: self.env.company)

    # v17: @api.model_create_multi is MANDATORY
    @api.model_create_multi
    def create(self, vals_list):
        return super().create(vals_list)

    def action_confirm(self):
        self.write({'state': 'confirmed'})
```

## View Template (v17 - NO attrs!)

```xml
<record id="model_view_form" model="ir.ui.view">
    <field name="name">custom.model.form</field>
    <field name="model">custom.model</field>
    <field name="arch" type="xml">
        <form>
            <header>
                <button name="action_confirm" string="Confirm" type="object"
                        class="btn-primary" invisible="state != 'draft'"/>
                <field name="state" widget="statusbar"/>
            </header>
            <sheet>
                <group>
                    <field name="name"/>
                    <field name="company_id" groups="base.group_multi_company"/>
                </group>
            </sheet>
            <div class="oe_chatter">
                <field name="message_follower_ids"/>
                <field name="activity_ids"/>
                <field name="message_ids"/>
            </div>
        </form>
    </field>
</record>
```

## v17 Visibility Syntax Examples

```xml
<!-- Simple condition -->
<field name="notes" invisible="state == 'draft'"/>

<!-- Multiple conditions -->
<field name="amount" invisible="state == 'draft' or state == 'cancelled'"/>

<!-- Using in operator -->
<field name="field" invisible="state in ('draft', 'cancelled')"/>

<!-- Group check -->
<field name="admin_field" invisible="not user_has_groups('base.group_system')"/>
```

## OWL Component Template (v17)

```javascript
/** @odoo-module **/

import { Component, useState, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";
import { registry } from "@web/core/registry";

export class MyComponent extends Component {
    static template = "module_name.MyComponent";

    setup() {
        this.orm = useService("orm");
        this.state = useState({ data: [] });

        onWillStart(async () => {
            this.state.data = await this.orm.searchRead("custom.model", [], ["name"]);
        });
    }
}

registry.category("actions").add("module_name.my_action", MyComponent);
```

## v17 Checklist

- [ ] **NO `attrs` in any view** - use direct `invisible`/`readonly`/`required`
- [ ] `@api.model_create_multi` for ALL create methods
- [ ] `Command` class for x2many operations
- [ ] `tracking=True` for tracked fields
- [ ] Python 3.10+ compatibility
- [ ] `company_ids` in multi-company record rules
