---
title: End-to-End Module Examples
domain: examples
version: all
edition: both
source: fhidalgo
status: active
---

# End-to-End Module Examples

## Example 1: Equipment Tracking Module (v18)

### User Request
```
"Create a module to track company equipment assigned to employees.
It should have equipment items with serial numbers, assignment history,
and maintenance schedules. Use Odoo 18 with multi-company support."
```

### Generated Output

#### File Tree
```
equipment_tracking/
├── __manifest__.py
├── __init__.py
├── models/
│   ├── __init__.py
│   ├── equipment_item.py
│   ├── equipment_category.py
│   └── equipment_assignment.py
├── views/
│   ├── equipment_item_views.xml
│   ├── equipment_category_views.xml
│   ├── equipment_assignment_views.xml
│   └── menuitems.xml
├── security/
│   ├── equipment_tracking_security.xml
│   └── ir.model.access.csv
├── data/
│   └── demo_data.xml
└── tests/
    ├── __init__.py
    ├── common.py
    └── test_equipment_item.py
```

#### models/equipment_item.py
```python
from odoo import api, fields, models
from odoo.exceptions import UserError


class EquipmentItem(models.Model):
    _name = 'equipment.item'
    _description = 'Equipment Item'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _check_company_auto = True
    _order = 'name'

    name = fields.Char(
        string='Equipment Name',
        required=True,
        tracking=True,
        index=True,
    )
    serial_number = fields.Char(
        string='Serial Number',
        index='btree_not_null',
        copy=False,
    )
    state = fields.Selection(
        selection=[
            ('available', 'Available'),
            ('assigned', 'Assigned'),
            ('maintenance', 'In Maintenance'),
            ('retired', 'Retired'),
        ],
        string='Status',
        default='available',
        required=True,
        tracking=True,
    )
    category_id = fields.Many2one(
        comodel_name='equipment.category',
        string='Category',
        check_company=True,
    )
    employee_id = fields.Many2one(
        comodel_name='hr.employee',
        string='Assigned To',
        tracking=True,
        check_company=True,
    )
    company_id = fields.Many2one(
        comodel_name='res.company',
        string='Company',
        required=True,
        readonly=True,
        default=lambda self: self.env.company,
        index=True,
    )
    currency_id = fields.Many2one(
        comodel_name='res.currency',
        string='Currency',
        related='company_id.currency_id',
    )
    purchase_date = fields.Date(string='Purchase Date')
    purchase_value = fields.Monetary(
        string='Purchase Value',
        currency_field='currency_id',
    )
    assignment_ids = fields.One2many(
        comodel_name='equipment.assignment',
        inverse_name='equipment_id',
        string='Assignment History',
    )
    assignment_count = fields.Integer(
        string='Assignments',
        compute='_compute_assignment_count',
    )

    def _compute_assignment_count(self) -> None:
        for record in self:
            record.assignment_count = len(record.assignment_ids)

    @api.model_create_multi
    def create(self, vals_list: list[dict]) -> 'EquipmentItem':
        return super().create(vals_list)

    def action_assign(self) -> bool:
        """Assign equipment to employee."""
        for record in self:
            if record.state != 'available':
                raise UserError(f"Equipment '{record.name}' is not available for assignment.")
            if not record.employee_id:
                raise UserError("Please select an employee before assigning.")
            record.state = 'assigned'
            self.env['equipment.assignment'].create({
                'equipment_id': record.id,
                'employee_id': record.employee_id.id,
                'date_assigned': fields.Date.today(),
            })
        return True
```

---

## Example 2: Quick Module for v17 (Minimal)

### User Request
```
"Create a simple task priority module for Odoo 17"
```

### Generated Output (v17 Pattern)

#### models/project_task.py
```python
from odoo import fields, models


class ProjectTask(models.Model):
    _inherit = 'project.task'

    x_priority_level = fields.Selection(
        selection=[
            ('low', 'Low'),
            ('medium', 'Medium'),
            ('high', 'High'),
            ('critical', 'Critical'),
        ],
        string='Priority Level',
        tracking=True,
    )
```

#### views/project_task_views.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <record id="project_task_view_form_inherit" model="ir.ui.view">
        <field name="name">project.task.form.inherit.priority</field>
        <field name="model">project.task</field>
        <field name="inherit_id" ref="project.view_task_form2"/>
        <field name="arch" type="xml">
            <xpath expr="//field[@name='user_ids']" position="after">
                <field name="x_priority_level"/>
            </xpath>
        </field>
    </record>
</odoo>
```

---

## Example 3: Upgrade Example (v16 → v18)

### Original Code (v16)
```python
# models/my_model.py (v16)
from odoo import api, fields, models

class MyModel(models.Model):
    _name = 'my.model'

    company_id = fields.Many2one('res.company')
    partner_id = fields.Many2one('res.partner')

    @api.model
    def create(self, vals):
        return super().create(vals)
```

### Updated Code (v18)
```python
# models/my_model.py (v18)
from odoo import api, fields, models


class MyModel(models.Model):
    _name = 'my.model'
    _check_company_auto = True  # ADDED for v18

    company_id = fields.Many2one(
        'res.company',
        required=True,
        default=lambda self: self.env.company,
    )
    partner_id = fields.Many2one(
        'res.partner',
        check_company=True,  # ADDED for v18
    )

    @api.model_create_multi  # CHANGED from @api.model
    def create(self, vals_list: list[dict]) -> 'MyModel':
        return super().create(vals_list)
```
