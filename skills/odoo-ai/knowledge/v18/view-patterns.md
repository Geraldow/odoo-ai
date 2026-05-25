---
title: Odoo 18 — View Patterns
domain: views
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — View Patterns

## Purpose
XML view patterns for Odoo 18, focusing on the modern attribute syntax and enhanced UI components.

## Visibility and State Syntax (v17/v18)
Starting from Odoo 17, the `attrs` attribute is removed. Use direct attributes with Python expressions.

| Legacy (v14-v16) | Modern (v17-v18) |
|------------------|------------------|
| `attrs="{'invisible': [('state', '=', 'draft')]}"` | `invisible="state == 'draft'"` |
| `attrs="{'readonly': [('state', '!=', 'draft')]}"` | `readonly="state != 'draft'"` |
| `attrs="{'required': [('type', '=', 'sale')]}"` | `required="type == 'sale'"` |

### Complex Expressions
```xml
<!-- AND condition -->
<field name="x" invisible="state == 'draft' and not is_manager"/>

<!-- OR condition -->
<field name="x" invisible="state == 'done' or state == 'cancel'"/>

<!-- In/Not In -->
<field name="x" invisible="state not in ('draft', 'sent')"/>

<!-- Parent access in One2many -->
<field name="x" invisible="parent.state != 'draft'"/>
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
                        class="btn-primary" invisible="state != 'draft'"/>
                <field name="state" widget="statusbar" statusbar_visible="draft,done"/>
            </header>
            <sheet>
                <div class="oe_button_box" name="button_box">
                    <button name="action_view_lines" type="object" class="oe_stat_button" icon="fa-list">
                        <field name="line_count" widget="statinfo" string="Lines"/>
                    </button>
                </div>
                <widget name="web_ribbon" title="Archived" bg_color="text-bg-danger" invisible="active"/>
                <div class="oe_title">
                    <label for="name"/>
                    <h1><field name="name" placeholder="e.g. Project Alpha"/></h1>
                </div>
                <group>
                    <group name="left">
                        <field name="partner_id"/>
                        <field name="date"/>
                    </group>
                    <group name="right">
                        <field name="company_id" groups="base.group_multi_company"/>
                        <field name="user_id" widget="many2one_avatar_user"/>
                    </group>
                </group>
                <notebook>
                    <page string="Lines" name="lines">
                        <field name="line_ids">
                            <list editable="bottom">
                                <field name="sequence" widget="handle"/>
                                <field name="product_id"/>
                                <field name="price_unit"/>
                                <field name="amount" sum="Total"/>
                            </list>
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

## List (Tree) View

In Odoo 18, `<tree>` and `<list>` are often interchangeable in `view_mode`, but the tag `<tree>` remains the standard in XML arch.

```xml
<record id="my_model_view_tree" model="ir.ui.view">
    <field name="name">my.model.tree</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <tree string="My Models" decoration-info="state == 'draft'" decoration-success="state == 'done'">
            <field name="sequence" widget="handle"/>
            <field name="name"/>
            <field name="partner_id"/>
            <!-- Optional columns -->
            <field name="user_id" optional="show"/>
            <field name="date" optional="hide"/>
            <!-- Conditional column visibility -->
            <field name="internal_notes" column_invisible="not context.get('show_notes')"/>
            <field name="state" widget="badge" 
                   decoration-info="state == 'draft'" 
                   decoration-success="state == 'done'"/>
        </tree>
    </field>
</record>
```

## Search View

```xml
<record id="my_model_view_search" model="ir.ui.view">
    <field name="name">my.model.search</field>
    <field name="model">my.model</field>
    <field name="arch" type="xml">
        <search>
            <field name="name"/>
            <field name="partner_id"/>
            <filter name="filter_draft" string="Draft" domain="[('state', '=', 'draft')]"/>
            <separator/>
            <filter name="group_partner" string="Partner" context="{'group_by': 'partner_id'}"/>
            <searchpanel>
                <field name="state" icon="fa-filter" enable_counters="1"/>
            </searchpanel>
        </search>
    </field>
</record>
```

## View Inheritance (XPath)

**Best Practice:** Always read the parent view structure before writing inheritance.

```xml
<record id="view_partner_form_inherit" model="ir.ui.view">
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
        <!-- Add field after another -->
        <xpath expr="//field[@name='email']" position="after">
            <field name="my_custom_field"/>
        </xpath>
        <!-- Modify attributes -->
        <xpath expr="//field[@name='phone']" position="attributes">
            <attribute name="required">1</attribute>
            <attribute name="readonly">state != 'draft'</attribute>
        </xpath>
    </field>
</record>
```

### Position Types
- `before`: Insert before matched element.
- `after`: Insert after matched element.
- `inside`: Insert as last child of matched element.
- `replace`: Replace the entire element.
- `attributes`: Change specific attributes of the element.

## Common Widgets

| Widget | Usage |
|--------|-------|
| `statusbar` | For the `state` field in header. |
| `badge` | Colored tags in list/form views. |
| `many2one_avatar_user` | Displays user photo + name. |
| `many2many_tags` | Compact display of M2M relations. |
| `boolean_toggle` | Switch style for Booleans. |
| `handle` | Drag & drop ordering in lists. |
| `monetary` | Formats number with currency symbol. |
| `priority` | Star-rating selection. |

## AI Agent Instructions
When generating Odoo 18.0 views:
1. **Never** use `attrs`. Use direct `invisible`, `readonly`, and `required`.
2. **Use** Python expressions in attributes (e.g., `invisible="state == 'done'"`).
3. **Use** `column_invisible` for tree/list columns that should be hidden conditionally.
4. **Prefer** `optional="show/hide"` for non-critical list columns.
5. **Always** include a `searchpanel` in search views for better UX.
6. **Ensure** `many2one_avatar_user` is used for user fields.
7. **Wrap** forms in `<sheet>` and include `<header>` with status buttons.
