---
title: Module Templates by App
domain: templates
version: all
edition: both
source: fhidalgo
status: active
---

# Module Templates by App

## Template Index

| Target App | Template | Common Use Cases |
|------------|----------|------------------|
| Sale | sale_extension | Custom fields, workflows, reports |
| Stock | stock_extension | Warehouse operations, tracking |
| HR | hr_extension | Employee data, custom leaves |
| CRM | crm_extension | Lead scoring, custom stages |
| Accounting | account_extension | Custom reports, fiscal positions |
| Website | website_extension | Pages, snippets, themes |
| Project | project_extension | Task types, time tracking |

## Sale Extension Template (v18)

### Model Extension
```python
# models/sale_order.py
from odoo import models, fields, api, _
from odoo.exceptions import UserError


class SaleOrder(models.Model):
    _inherit = 'sale.order'

    # Custom fields
    x_custom_reference = fields.Char(
        string='Custom Reference',
        tracking=True,
        copy=False,
    )

    x_approval_required = fields.Boolean(
        string='Requires Approval',
        compute='_compute_approval_required',
        store=True,
    )

    # Computed field
    @api.depends('amount_total')
    def _compute_approval_required(self):
        approval_threshold = 10000.0
        for order in self:
            order.x_approval_required = order.amount_total > approval_threshold

    # Action methods
    def action_request_approval(self):
        """Request approval for high-value orders"""
        for order in self:
            if not order.x_approval_required:
                raise UserError(_("This order does not require approval."))
            order.message_post(
                body=_("Approval requested for order %s") % order.name,
                subtype_xmlid='mail.mt_note',
            )
```

### View Extension
```xml
<!-- views/sale_order_views.xml -->
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <record id="view_order_form_inherit" model="ir.ui.view">
        <field name="name">sale.order.form.inherit.extension</field>
        <field name="model">sale.order</field>
        <field name="inherit_id" ref="sale.view_order_form"/>
        <field name="arch" type="xml">
            <field name="client_order_ref" position="after">
                <field name="x_custom_reference"/>
            </field>
        </xpath>
    </record>
</odoo>
```

---

## Stock Extension Template (v18)

### Model Extension
```python
# models/stock_picking.py
from odoo import models, fields, api, _


class StockPicking(models.Model):
    _inherit = 'stock.picking'
    _check_company_auto = True

    x_vehicle_id = fields.Many2one(
        'fleet.vehicle',
        string='Delivery Vehicle',
        check_company=True,
        tracking=True,
    )

    x_driver_id = fields.Many2one(
        'hr.employee',
        string='Driver',
        check_company=True,
        tracking=True,
    )
```

---

## CRM Extension Template (v18)

### Lead Scoring Model
```python
# models/crm_lead.py
from odoo import models, fields, api, _


class CrmLead(models.Model):
    _inherit = 'crm.lead'

    x_score = fields.Integer(
        string='Lead Score',
        compute='_compute_score',
        store=True,
        tracking=True,
    )

    @api.depends('email_from', 'phone', 'partner_id', 'expected_revenue')
    def _compute_score(self):
        for lead in self:
            score = 0
            if lead.email_from: score += 10
            if lead.phone: score += 10
            lead.x_score = score
```

---

## Usage Instructions for Agents

When generating a module that extends a common app:

1. **Identify the target app** (sale, stock, hr, crm, project, website, account)
2. **Load this template file** as a reference
3. **Load the version-specific files** for your target version
4. **Adapt the template** to the specific requirements
5. **Apply version-specific patterns** (attrs, Command class, etc.)
