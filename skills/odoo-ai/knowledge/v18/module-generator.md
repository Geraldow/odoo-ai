---
title: Odoo 18 — Module Generator
domain: scaffold
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Module Generator

## Purpose
Module scaffolding, manifest keys, and organization for Odoo 18.

## Module Structure (v18)
Follow the standard OCA-aligned directory structure.

```text
my_module/
├── __init__.py
├── __manifest__.py
├── data/                  # XML/CSV data files
├── demo/                  # Demo data
├── i18n/                  # Translation files
├── models/                # Python ORM models
│   ├── __init__.py
│   └── my_model.py
├── security/              # Access rules and groups
│   ├── ir.model.access.csv
│   └── my_module_security.xml
├── static/                # Assets
│   ├── description/       # icon.png
│   └── src/               # OWL components, JS, SCSS, XML
├── tests/                 # Unit/Integration tests
├── views/                 # XML views and menus
│   ├── my_model_views.xml
│   └── menus.xml
└── wizard/                # Transient models
```

## __manifest__.py (v18)
```python
{
    'name': 'My Module Title',
    'version': '18.0.1.0.0',
    'category': 'Sales',
    'summary': 'Short module description',
    'author': 'Antigravity',
    'license': 'LGPL-3',
    'depends': ['base', 'mail'],
    'data': [
        'security/my_module_security.xml',
        'security/ir.model.access.csv',
        'views/my_model_views.xml',
        'views/menus.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'my_module/static/src/**/*.js',
            'my_module/static/src/**/*.xml',
        ],
    },
    'installable': True,
    'application': False,
}
```

## ORM Model Template (v18)
```python
from odoo import api, fields, models, Command, _
from odoo.tools import SQL

class MyModel(models.Model):
    _name = 'my_module.my_model'
    _description = 'Description'
    _check_company_auto = True

    name = fields.Char(required=True, tracking=True)
    company_id = fields.Many2one('res.company', required=True, default=lambda self: self.env.company)
    partner_id = fields.Many2one('res.partner', check_company=True)

    @api.model_create_multi
    def create(self, vals_list):
        return super().create(vals_list)
```

## View Template (v18)
```xml
<record id="my_model_view_form" model="ir.ui.view">
    <field name="model">my_module.my_model</field>
    <field name="arch" type="xml">
        <form>
            <header>
                <button name="action_do" type="object" string="Do" invisible="state != 'draft'"/>
                <field name="state" widget="statusbar"/>
            </header>
            <sheet>
                <group>
                    <field name="name"/>
                    <field name="partner_id"/>
                </group>
            </sheet>
        </form>
    </field>
</record>
```

## OWL 2.x Component Template
```javascript
/** @odoo-module **/
import { Component, useState } from "@odoo/owl";
import { registry } from "@web/core/registry";

export class MyComponent extends Component {
    static template = "my_module.MyComponent";
    setup() {
        this.state = useState({ value: 0 });
    }
}
registry.category("actions").add("my_module.my_action", MyComponent);
```

## Testing Template
```python
from odoo.tests import TransactionCase, tagged

@tagged('post_install', '-at_install')
class TestMyModule(TransactionCase):
    def test_logic(self):
        record = self.env['my_module.my_model'].create({'name': 'Test'})
        self.assertEqual(record.name, 'Test')
```

## v18 Generation Checklist
- [ ] Module version starts with `18.0.x.x.x`.
- [ ] `_check_company_auto = True` in multi-company models.
- [ ] `check_company=True` on Many2one fields.
- [ ] `@api.model_create_multi` for all `create` methods.
- [ ] XML views use direct `invisible` (no `attrs`).
- [ ] Record rules use `allowed_company_ids`.
- [ ] Type hints included in Python models.
- [ ] `SQL()` builder used for any raw SQL.

## AI Agent Instructions
When generating Odoo 18.0 modules:
1. **Always** use the modern scaffold structure.
2. **Apply** `_check_company_auto = True` and `check_company=True` by default for multi-company support.
3. **Include** Python type hints in models (`field: type = fields.Type(...)`).
4. **Use** `SQL()` for raw database interactions.
5. **Implement** `create` methods with the multi-create pattern.
6. **Set** `invisible`, `readonly`, `required` directly in XML attributes.
7. **Ensure** `allowed_company_ids` is used in security rules.
