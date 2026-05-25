---
title: Odoo 19 — Reports Reference
domain: reports
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Reports Reference

Reports in Odoo 19 are generated using the **QWeb** XML engine, rendered into HTML, and optionally converted to PDF via `wkhtmltopdf`.

## QWeb Templating Essentials

Common directives for building dynamic report layouts:

| Directive | Purpose | Example |
|-----------|---------|---------|
| `t-foreach` | Iterates over recordsets. | `<tr t-foreach="docs" t-as="o">` |
| `t-field` | Renders a field with Odoo's widget logic. | `<span t-field="o.date_order"/>` |
| `t-if` / `t-elif` | Conditional visibility. | `<div t-if="o.amount_untaxed > 0">` |
| `t-call` | Includes another template (layout/header). | `<t t-call="web.external_layout">` |
| `t-lang` | Switches the translation context. | `<t t-lang="o.partner_id.lang">` |
| `t-options` | Configures field rendering (e.g. date format). | `<span t-field="o.date" t-options='{"widget": "date"}'/>` |

## Report Action Registration

Reports are defined in XML as `ir.actions.report` records.

```xml
<record id="action_report_invoice" model="ir.actions.report">
    <field name="name">Customer Invoice</field>
    <field name="model">account.move</field>
    <field name="report_type">qweb-pdf</field>
    <field name="report_name">account.report_invoice_with_payments</field>
    <field name="print_report_name">(object._get_report_base_filename())</field>
    <field name="binding_model_id" ref="model_account_move"/>
    <field name="binding_type">report</field>
</record>
```

## Paperformat Configuration

Controls physical page properties like margins, orientation, and resolution.

```xml
<record id="paperformat_custom_a4" model="report.paperformat">
    <field name="name">Custom A4 Portrait</field>
    <field name="format">A4</field>
    <field name="orientation">Portrait</field>
    <field name="margin_top">30</field>
    <field name="header_spacing">25</field>
    <field name="dpi">96</field>
</record>
```
Apply to a report via the `paperformat_id` field in the report action.

## Customizing Report Data

To inject custom variables or perform complex calculations for a report, create an `AbstractModel` following the naming convention `report.<module>.<template_id>`.

```python
class CustomReport(models.AbstractModel):
    _name = 'report.my_module.my_report_template'
    _description = 'Custom Data for My Report'

    def _get_report_values(self, docids, data=None):
        docs = self.env['my.model'].browse(docids)
        return {
            'doc_ids': docids,
            'doc_model': 'my.model',
            'docs': docs,
            'custom_data': self._calculate_complex_values(docs),
        }
```

## Barcodes and Assets
- **Barcodes**: Use the `barcode` controller: `<img t-att-src="'/report/barcode/?type=%s&amp;value=%s' % ('Code128', o.name)"/>`.
- **CSS**: Place report-specific styles in the `web.report_assets_common` or `web.report_assets_pdf` bundles.
