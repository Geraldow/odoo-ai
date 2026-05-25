---
title: Report Patterns (QWeb PDF)
domain: patterns
version: all
edition: both
source: fhidalgo+peterurban+ahmedlakos
status: active
---

# Report Patterns (QWeb PDF)

## PDF Report Definition

### Report Action (XML)
```xml
<?xml version="1.0" encoding="utf-8"?>
<odoo>
    <!-- Report Action -->
    <record id="report_my_model" model="ir.actions.report">
        <field name="name">My Report</field>
        <field name="model">my.model</field>
        <field name="report_type">qweb-pdf</field>
        <field name="report_name">my_module.report_my_model_document</field>
        <field name="report_file">my_module.report_my_model_document</field>
        <field name="print_report_name">'MyReport - %s' % object.name</field>
        <field name="binding_model_id" ref="model_my_model"/>
        <field name="binding_type">report</field>
        <field name="paperformat_id" ref="base.paperformat_euro"/>
    </record>

    <!-- Report Template -->
    <template id="report_my_model_document">
        <t t-call="web.html_container">
            <t t-foreach="docs" t-as="doc">
                <t t-call="web.external_layout">
                    <div class="page">
                        <h2>
                            <span t-field="doc.name"/>
                        </h2>

                        <div class="row mt-4">
                            <div class="col-6">
                                <strong>Customer:</strong>
                                <span t-field="doc.partner_id.name"/>
                            </div>
                            <div class="col-6 text-end">
                                <strong>Date:</strong>
                                <span t-field="doc.date"/>
                            </div>
                        </div>

                        <table class="table table-sm mt-4">
                            <thead>
                                <tr>
                                    <th>Description</th>
                                    <th class="text-end">Quantity</th>
                                    <th class="text-end">Price</th>
                                    <th class="text-end">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                <t t-foreach="doc.line_ids" t-as="line">
                                    <tr>
                                        <td><span t-field="line.name"/></td>
                                        <td class="text-end">
                                            <span t-field="line.quantity"/>
                                        </td>
                                        <td class="text-end">
                                            <span t-field="line.price_unit"
                                                  t-options='{"widget": "monetary",
                                                              "display_currency": doc.currency_id}'/>
                                        </td>
                                        <td class="text-end">
                                            <span t-field="line.subtotal"
                                                  t-options='{"widget": "monetary",
                                                              "display_currency": doc.currency_id}'/>
                                        </td>
                                    </tr>
                                </t>
                            </tbody>
                            <tfoot>
                                <tr>
                                    <td colspan="3" class="text-end">
                                        <strong>Total:</strong>
                                    </td>
                                    <td class="text-end">
                                        <strong>
                                            <span t-field="doc.amount_total"
                                                  t-options='{"widget": "monetary",
                                                              "display_currency": doc.currency_id}'/>
                                        </strong>
                                    </td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </t>
            </t>
        </t>
    </template>
</odoo>
```

---

## QWeb Template Syntax

### Basic Output
```xml
<!-- Text content -->
<span t-field="doc.name"/>

<!-- With formatting -->
<span t-field="doc.date" t-options='{"format": "dd/MM/yyyy"}'/>

<!-- Raw output (no escaping) -->
<span t-out="doc.html_content"/>

<!-- Escaped output -->
<span t-esc="doc.description"/>
```

### Conditionals
```xml
<!-- If -->
<div t-if="doc.state == 'draft'">
    <span class="badge bg-secondary">Draft</span>
</div>

<!-- If-Else -->
<t t-if="doc.amount > 0">
    <span class="text-success" t-field="doc.amount"/>
</t>
<t t-else="">
    <span class="text-muted">0.00</span>
</t>
```
