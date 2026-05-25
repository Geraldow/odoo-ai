---
title: Odoo 15 — View Patterns
domain: views
version: 15.0
edition: community
source: legacy
status: active
---

# Odoo 15 — View Patterns

## Form View Structure
Odoo 15 follows the classic form view structure with `header`, `sheet`, and `chatter`.

```xml
<record id="my_model_view_form" model="ir.ui.view">
    <field name="name">my.model.form</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <form string="My Model">
            <header>
                <button name="action_confirm" type="object" string="Confirm" class="btn-primary" 
                        attrs="{'invisible': [('state', '!=', 'draft')]}"/>
                <field name="state" widget="statusbar" statusbar_visible="draft,confirmed,done"/>
            </header>
            <sheet>
                <div class="oe_title">
                    <h1><field name="name" placeholder="Name"/></h1>
                </div>
                <group>
                    <group>
                        <field name="partner_id" attrs="{'required': [('state', '=', 'confirmed')]}"/>
                        <field name="date"/>
                    </group>
                    <group>
                        <field name="user_id"/>
                        <field name="company_id" groups="base.group_multi_company"/>
                    </group>
                </group>
                <notebook>
                    <page string="Lines" name="lines">
                        <field name="line_ids">
                            <tree editable="bottom">
                                <field name="sequence" widget="handle"/>
                                <field name="product_id"/>
                                <field name="quantity"/>
                                <field name="price_unit"/>
                                <field name="subtotal"/>
                            </tree>
                        </field>
                    </page>
                </notebook>
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

## Visibility and Attributes (attrs)
In Odoo 15, conditional visibility, required, and readonly attributes are handled via the `attrs` dictionary.

```xml
<field name="partner_id"
       attrs="{'invisible': [('state', '=', 'draft')],
               'readonly': [('state', '!=', 'draft')],
               'required': [('type', '=', 'customer')]}"/>

<button name="action_do_something"
        attrs="{'invisible': [('state', '!=', 'draft')]}"/>

<group attrs="{'invisible': [('show_details', '=', False)]}">
    <field name="detail_info"/>
</group>
```

### Expression Conversion Table (attrs syntax)

| Logic | attrs Domain |
|-------|--------------|
| Equals | `[('field', '=', 'value')]` |
| Not Equals | `[('field', '!=', 'value')]` |
| Is True | `[('field', '=', True)]` |
| Is False | `[('field', '=', False)]` |
| In List | `[('field', 'in', ['a','b'])]` |
| Greater than | `[('field', '>', 0)]` |
| AND | `['&', A, B]` (implicit) |
| OR | `['|', A, B]` |

## Tree/List View
The `tree` view in v15 supports decorations for row coloring.

```xml
<tree string="My Models"
      decoration-info="state == 'draft'"
      decoration-success="state == 'done'"
      decoration-danger="state == 'cancel'">
    <field name="sequence" widget="handle"/>
    <field name="name"/>
    <field name="partner_id"/>
    <field name="date"/>
    <field name="state" widget="badge"
           decoration-success="state == 'done'"
           decoration-warning="state == 'draft'"/>
    <field name="amount" sum="Total"/>
</tree>
```

## Search View
Search views allow filtering, grouping, and search panels.

```xml
<record id="my_model_view_search" model="ir.ui.view">
    <field name="name">my.model.search</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <search string="Search My Model">
            <field name="name"/>
            <field name="partner_id"/>
            <filter name="draft" string="Draft" domain="[('state', '=', 'draft')]"/>
            <group expand="0" string="Group By">
                <filter name="group_partner" string="Partner" context="{'group_by': 'partner_id'}"/>
            </group>
            <searchpanel>
                <field name="state" icon="fa-filter" enable_counters="1"/>
            </searchpanel>
        </search>
    </field>
</record>
```

## View Inheritance
Standard XPath inheritance patterns are used to modify existing views.

```xml
<record id="view_partner_form_inherit" model="ir.ui.view">
    <field name="name">res.partner.form.inherit.my_module</field>
    <field name="model">res.partner</field>
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="arch" type="xml">
        <xpath expr="//field[@name='email']" position="after">
            <field name="x_custom_field"/>
        </xpath>
        <xpath expr="//field[@name='phone']" position="attributes">
            <attribute name="required">1</attribute>
        </xpath>
    </field>
</record>
```
