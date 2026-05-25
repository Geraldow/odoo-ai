---
title: Odoo 18 — Reports Reference
domain: reports
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Reports Reference

Odoo uses **QWeb** (an XML templating engine) to generate HTML, which is then converted to PDF using `wkhtmltopdf`.

## QWeb Template Directives

Common directives used in report templates:

| Directive | Description | Example |
|-----------|-------------|---------|
| `t-foreach` | Loop through a collection. | `<tr t-foreach="docs" t-as="o">` |
| `t-field` | Output a field value with Odoo formatting. | `<span t-field="o.name"/>` |
| `t-if` | Conditional logic. | `<div t-if="o.amount_total > 100">...</div>` |
| `t-esc` | Output a value as escaped text. | `<span t-esc="o.partner_id.name"/>` |
| `t-call` | Include another template (e.g., headers). | `<t t-call="web.external_layout">` |
| `t-lang` | Set the language for the block. | `<t t-lang="o.partner_id.lang">` |

## Report Action XML

To register a report, define an `ir.actions.report` record.

```xml
<record id="action_report_my_model" model="ir.actions.report">
    <field name="name">My Custom Report</field>
    <field name="model">my.module.model</field>
    <field name="report_type">qweb-pdf</field>
    <field name="report_name">my_module.report_template_id</field>
    <field name="report_file">my_module.report_template_id</field>
    <field name="print_report_name">'Report - %s' % (object.name)</field>
    <field name="binding_model_id" ref="model_my_module_model"/>
    <field name="binding_type">report</field>
</record>
```

## Paperformat Configuration

Controls the layout (margins, orientation, paper size).

```xml
<record id="paperformat_french_a4" model="report.paperformat">
    <field name="name">French A4</field>
    <field name="default" eval="True"/>
    <field name="format">A4</field>
    <field name="orientation">Portrait</field>
    <field name="margin_top">40</field>
    <field name="margin_bottom">20</field>
    <field name="header_spacing">35</field>
    <field name="dpi">90</field>
</record>
```
Link it to the report action using the `paperformat_id` field.

## Advanced Reports

### Custom Data Calculation
To pass custom variables to a report, override the `_get_report_values` method of the `report.module_name.report_name` model.

```python
class MyReport(models.AbstractModel):
    _name = 'report.my_module.report_template_id'

    def _get_report_values(self, docids, data=None):
        docs = self.env['my.model'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'my.model',
            'docs': docs,
            'custom_value': 'Hello World',
        }
```
