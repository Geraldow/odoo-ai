---
title: Odoo 14 — View Patterns
domain: views
version: 14.0
edition: community
source: legacy
status: active
---

# Odoo 14 — View Patterns

## Form View
Odoo 14 uses `attrs` for all conditional visibility and field states.

```xml
<record id="my_model_view_form" model="ir.ui.view">
    <field name="name">my.model.form</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <form string="My Model">
            <header>
                <button name="action_confirm" string="Confirm" type="object" class="btn-primary"
                        attrs="{'invisible': [('state', '!=', 'draft')]}"/>
                <field name="state" widget="statusbar"/>
            </header>
            <sheet>
                <div class="oe_title">
                    <h1><field name="name" placeholder="Name..."/></h1>
                </div>
                <group>
                    <group>
                        <field name="partner_id" attrs="{'required': [('state', '=', 'confirmed')]}"/>
                    </group>
                    <group>
                        <field name="user_id"/>
                        <field name="company_id" groups="base.group_multi_company"/>
                    </group>
                </group>
                <notebook>
                    <page string="Lines">
                        <field name="line_ids">
                            <tree editable="bottom">
                                <field name="product_id"/>
                                <field name="quantity"/>
                                <field name="price_unit"/>
                            </tree>
                        </field>
                    </page>
                </notebook>
            </sheet>
            <div class="oe_chatter">
                <field name="message_follower_ids" widget="mail_followers"/>
                <field name="activity_ids" widget="mail_activity"/>
                <field name="message_ids" widget="mail_thread"/>
            </div>
        </form>
    </field>
</record>
```

## Attribute Expressions (attrs)
Odoo 14 visibility logic MUST be contained within the `attrs` attribute as a Python dictionary mapping properties to domain expressions.

```xml
<field name="secret_code" 
       attrs="{'invisible': [('state', '=', 'draft')], 
               'readonly': [('state', '=', 'done')]}"/>

<button name="do_action" 
        attrs="{'invisible': ['|', ('state', '=', 'done'), ('active', '=', False)]}"/>
```

## List/Tree View
v14 Tree views support decorations based on simple conditions.

```xml
<tree decoration-info="state == 'draft'" decoration-muted="state == 'cancel'">
    <field name="name"/>
    <field name="partner_id"/>
    <field name="state"/>
</tree>
```

## Kanban View
v14 Kanban uses QWeb templates for card layout.

```xml
<kanban>
    <field name="id"/>
    <field name="name"/>
    <templates>
        <t t-name="kanban-box">
            <div class="oe_kanban_global_click">
                <div class="oe_kanban_details">
                    <strong class="o_kanban_record_title">
                        <field name="name"/>
                    </strong>
                </div>
            </div>
        </t>
    </templates>
</kanban>
```

## Inheritance (XPath)
Standard XPath patterns for extending views.

```xml
<xpath expr="//field[@name='partner_id']" position="after">
    <field name="new_field"/>
</xpath>

<xpath expr="//header" position="inside">
    <button name="new_action" string="Extra Action" type="object"/>
</xpath>
```

## Widgets in v14
- `statusbar`: Status flow.
- `many2many_tags`: Multiple selection chips.
- `monetary`: Currency-formatted numbers.
- `mail_thread`: Legacy chatter widget.
- `mail_followers`: Legacy followers widget.
