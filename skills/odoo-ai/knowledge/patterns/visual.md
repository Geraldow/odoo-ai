---
title: Visual Stack Patterns (v17/18/19)
domain: patterns
version: all
edition: both
source: fhidalgo+peterurban+ahmedlakos
status: active
---

# Visual Stack Patterns (v17/18/19)

## PDF Report Visualization

### QWeb Report with Translations
```xml
<template id="report_my_document">
    <t t-call="web.html_container">
        <t t-foreach="docs" t-as="doc">
            <t t-call="web.external_layout">
                <div class="page">
                    <!-- Translatable text -->
                    <h1>Order Confirmation</h1>

                    <table>
                        <thead>
                            <tr>
                                <!-- Column headers translatable -->
                                <th>Product</th>
                                <th>Quantity</th>
                                <th>Price</th>
                            </tr>
                        </thead>
                        <tbody>
                            <t t-foreach="doc.line_ids" t-as="line">
                                <tr>
                                    <!-- Product name in document language -->
                                    <td t-esc="line.product_id.with_context(lang=doc.partner_id.lang).name"/>
                                    <td t-esc="line.quantity"/>
                                    <td t-field="line.price_unit"/>
                                </tr>
                            </t>
                        </tbody>
                    </table>

                    <!-- Translated footer -->
                    <p>Thank you for your order!</p>
                </div>
            </t>
        </t>
    </t>
</template>
```

## Email Visualization

### Email Template Data
```xml
<!-- Email template -->
<record id="email_template_confirmation" model="mail.template">
    <field name="name">Confirmation Email</field>
    <field name="subject">Order {{ object.name }} Confirmed</field>
    <field name="body_html"><![CDATA[
        <div style="margin: 0px; padding: 0px;">
            <p style="margin: 0px; padding: 0px; font-size: 13px;">
                Dear {{ object.partner_id.name }},<br/><br/>
                Your order <strong>{{ object.name }}</strong> has been confirmed.
                <br/><br/>
                Thank you for your business!
            </p>
        </div>
    ]]></field>
</record>
```
