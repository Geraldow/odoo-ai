---
title: Actions Master Reference
domain: api
version: 18.0
edition: both
source: native
status: active
---

# Actions Master Reference

## Overview
Actions in Odoo define how the system responds to user interactions. They are stored in the `ir.actions.actions` table and specialized into several models.

## ir.actions.act_window
The most common action type, used to open views (list, form, kanban, etc.) for a specific model.

### XML Example
```xml
<record id="action_partner_form" model="ir.actions.act_window">
    <field name="name">Customers</field>
    <field name="res_model">res.partner</field>
    <field name="view_mode">list,kanban,form</field>
    <field name="domain">[('is_company', '=', True)]</field>
    <field name="context">{'default_is_company': True}</field>
    <field name="help" type="html">
        <p class="o_view_nocontent_smiling_face">
            Create a new customer
        </p>
    </field>
</record>
```

## ir.actions.server
Executes Python code or pre-defined operations on the server side.

### Python Example (Triggering from a method)
```python
def action_custom_server_trigger(self):
    return self.env.ref('my_module.action_id').read()[0]
```

## ir.actions.client
Triggers logic on the client side (web browser). These actions are defined in JavaScript and can open custom screens or trigger UI behaviors.

### XML Example
```xml
<record id="action_client_example" model="ir.actions.client">
    <field name="name">My Custom Dashboard</field>
    <field name="tag">my_custom_dashboard_tag</field>
</record>
```

## ir.actions.report
Triggers the generation and downloading of a PDF or HTML report.

### XML Example
```xml
<record id="action_report_invoice" model="ir.actions.report">
    <field name="name">Invoices</field>
    <field name="model">account.move</field>
    <field name="report_type">qweb-pdf</field>
    <field name="report_name">account.report_invoice_with_payments</field>
    <field name="report_file">account.report_invoice_with_payments</field>
    <field name="print_report_name">(object._get_report_base_filename())</field>
    <field name="binding_model_id" ref="account.model_account_move"/>
    <field name="binding_type">report</field>
</record>
```

## ir.actions.act_url
Redirects the user to a specific URL, either in the same window or a new one.

### XML Example
```xml
<record id="action_open_external_link" model="ir.actions.act_url">
    <field name="name">Open Website</field>
    <field name="url">https://www.odoo.com</field>
    <field name="target">new</field>
</record>
```

## Context and Domain Handling
- **Context:** Used to pass data to the view, set default values, or trigger specific logic in `default_get` or `search`.
- **Domain:** Filters the records displayed in the view. It can be a static list or a dynamic string evaluated on the client.
