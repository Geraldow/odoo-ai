---
title: Odoo 19 — View Patterns
domain: views
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — View Patterns

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ODOO 19.0 VIEW CONVENTIONS                                                  ║
║  <list> Tag Mandatory | Inline Expressions | t-name="card" | OWL 3.0         ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## List View (formerly Tree)
In Odoo 19, the `<list>` tag is mandatory and replaces the legacy `<tree>` tag for displaying record sets.

```xml
<record id="view_custom_model_list" model="ir.ui.view">
    <field name="name">custom.model.list</field>
    <field name="model">custom.model</field>
    <field name="arch" type="xml">
        <list string="Records" 
              decoration-info="state == 'draft'"
              decoration-success="state == 'done'"
              multi_edit="1">
            <field name="name"/>
            <field name="partner_id" optional="show"/>
            <field name="date"/>
            <field name="amount" sum="Total"/>
            <field name="state" widget="badge" 
                   decoration-info="state == 'draft'"
                   decoration-success="state == 'done'"/>
            <!-- Use column_invisible for list-specific hiding -->
            <field name="company_id" groups="base.group_multi_company" column_invisible="parent.state == 'done'"/>
        </list>
    </field>
</record>
```

## Form View
Form views utilize inline attributes for visibility and state management.

```xml
<record id="view_custom_model_form" model="ir.ui.view">
    <field name="name">custom.model.form</field>
    <field name="model">custom.model</field>
    <field name="arch" type="xml">
        <form>
            <header>
                <button name="action_confirm" string="Confirm" type="object" 
                        class="btn-primary" invisible="state != 'draft'"/>
                <field name="state" widget="statusbar"/>
            </header>
            <sheet>
                <div class="oe_title">
                    <h1><field name="name" placeholder="Title..."/></h1>
                </div>
                <group>
                    <group>
                        <field name="partner_id" readonly="state != 'draft'"/>
                        <field name="date" required="state == 'done'"/>
                    </group>
                    <group>
                        <field name="amount"/>
                        <field name="company_id" groups="base.group_multi_company"/>
                    </group>
                </group>
                <notebook>
                    <page string="Details" name="details">
                        <field name="line_ids">
                            <list editable="bottom">
                                <field name="product_id"/>
                                <field name="qty"/>
                                <field name="price_unit"/>
                                <field name="price_subtotal"/>
                            </list>
                        </field>
                    </page>
                </notebook>
            </sheet>
            <div class="oe_chatter">
                <field name="message_follower_ids"/>
                <field name="message_ids"/>
            </div>
        </form>
    </field>
</record>
```

## Kanban View (v19 Templates)
Kanban views now use the `t-name="card"` syntax for defining card templates.

```xml
<record id="view_custom_model_kanban" model="ir.ui.view">
    <field name="name">custom.model.kanban</field>
    <field name="model">custom.model</field>
    <field name="arch" type="xml">
        <kanban default_group_by="state">
            <templates>
                <t t-name="card">
                    <div class="oe_kanban_global_click d-flex flex-column">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <strong class="o_kanban_record_title">
                                <field name="name"/>
                            </strong>
                            <field name="state" widget="label_selection" 
                                   options="{'classes': {'draft': 'default', 'done': 'success'}}"/>
                        </div>
                        <div class="text-muted small">
                            <field name="partner_id"/>
                        </div>
                        <div class="mt-auto d-flex justify-content-between">
                            <field name="activity_ids" widget="kanban_activity"/>
                            <field name="user_id" widget="many2one_avatar_user"/>
                        </div>
                    </div>
                </t>
            </templates>
        </kanban>
    </field>
</record>
```

## Search View
```xml
<record id="view_custom_model_search" model="ir.ui.view">
    <field name="name">custom.model.search</field>
    <field name="model">custom.model</field>
    <field name="arch" type="xml">
        <search>
            <field name="name"/>
            <field name="partner_id"/>
            <filter string="My Records" name="my_records" domain="[('user_id', '=', uid)]"/>
            <group expand="0" string="Group By">
                <filter string="Partner" name="group_by_partner" context="{'group_by': 'partner_id'}"/>
            </group>
            <searchpanel>
                <field name="state" icon="fa-filter" enable_counters="1"/>
            </searchpanel>
        </search>
    </field>
</record>
```

## View Inheritance Patterns
Use `xpath` to modify existing views. Always verify the parent arch before inheriting.

```xml
<record id="view_partner_form_inherit" model="ir.ui.view">
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <xpath expr="//field[@name='email']" position="after">
            <field name="x_custom_field" invisible="not is_company"/>
        </xpath>
    </field>
</record>
```

## Summary of Visibility Attributes (v17+)
| Legacy (v14-v16) | Odoo 19 |
| :--- | :--- |
| `attrs="{'invisible': [('f', '=', 'v')]}"` | `invisible="f == 'v'"` |
| `attrs="{'readonly': [('f', '!=', 'v')]}"` | `readonly="f != 'v'"` |
| `attrs="{'required': [('f', '=', True)]}"` | `required="f"` |
| `tree` tag | `list` tag |
| `t-name="kanban-box"` | `t-name="card"` |
| `invisible="1"` (in Tree) | `column_invisible="True"` |
