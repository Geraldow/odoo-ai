---
title: Odoo 16 — View Patterns
domain: views
version: 16.0
edition: community
source: legacy
status: active
---

# Odoo 16 — View Patterns

## Purpose
XML view patterns and form/list/kanban structure for Odoo 16.

## Visibility Syntax (v16 Transition)

Odoo 16 is a transition version where `attrs` is deprecated but still works, and the new inline syntax is recommended.

### v14-v16: attrs Syntax (Deprecated)
```xml
<!-- DEPRECATED in v16, REMOVED in v17 -->
<field name="partner_id"
       attrs="{'invisible': [('state', '=', 'draft')],
               'readonly': [('state', '!=', 'draft')],
               'required': [('type', '=', 'customer')]}"/>

<button name="action"
        attrs="{'invisible': [('state', '!=', 'draft')]}"/>
```

### v16+ Recommended: Inline Expression Syntax
```xml
<!-- RECOMMENDED in v16, REQUIRED in v17+ -->
<field name="partner_id"
       invisible="state == 'draft'"
       readonly="state != 'draft'"
       required="type == 'customer'"/>

<button name="action"
        invisible="state != 'draft'"/>
```

## Form View Structure

```xml
<record id="my_model_view_form" model="ir.ui.view">
    <field name="name">my.model.form</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <form string="My Model">
            <header>
                <button name="action_confirm" type="object" string="Confirm"
                        class="btn-primary"
                        invisible="state != 'draft'"/>
                <field name="state" widget="statusbar"
                       statusbar_visible="draft,confirmed,done"/>
            </header>
            <sheet>
                <div class="oe_title">
                    <h1>
                        <field name="name" placeholder="Name"
                               readonly="state == 'done'"/>
                    </h1>
                </div>
                <group>
                    <group>
                        <field name="partner_id" readonly="state == 'done'"/>
                        <field name="date"/>
                    </group>
                    <group>
                        <field name="company_id" groups="base.group_multi_company"/>
                    </group>
                </group>
                <notebook>
                    <page string="Lines" name="lines">
                        <field name="line_ids" readonly="state == 'done'">
                            <tree editable="bottom">
                                <field name="sequence" widget="handle"/>
                                <field name="name"/>
                                <field name="quantity"/>
                                <field name="price"/>
                                <field name="amount" sum="Total"/>
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

## Tree/List View

```xml
<record id="my_model_view_tree" model="ir.ui.view">
    <field name="name">my.model.tree</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <tree string="My Models"
              decoration-info="state == 'draft'"
              decoration-success="state == 'done'">
            <field name="name"/>
            <field name="partner_id"/>
            <field name="date"/>
            <field name="state" widget="badge"
                   decoration-success="state == 'done'"
                   decoration-info="state == 'draft'"/>
            <field name="amount" sum="Total"/>
        </tree>
    </field>
</record>
```

## View Inheritance (v16)

```xml
<record id="view_partner_form_inherit" model="ir.ui.view">
    <field name="name">res.partner.form.inherit.my_module</field>
    <field name="model">res.partner</field>
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="arch" type="xml">
        <xpath expr="//field[@name='email']" position="after">
            <field name="x_custom_field" invisible="not is_company"/>
        </xpath>
    </field>
</record>
```

## Common Widgets in v16

| Widget | Field Types | Purpose |
|--------|-------------|---------|
| `statusbar` | Selection | Status bar display |
| `badge` | Selection | Colored badge |
| `many2one_avatar_user` | Many2one | User avatar |
| `many2many_tags` | Many2many | Tag chips |
| `boolean_toggle` | Boolean | Toggle switch |
| `handle` | Integer | Drag handle |
