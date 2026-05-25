---
title: Odoo 17 — View Patterns
domain: views
version: 17.0
edition: community
source: legacy
status: active
---

# Odoo 17 — View Patterns

## Visibility Syntax (v17+ Required)

### Inline Expression Syntax
The `attrs` attribute is completely removed in v17. You must use direct attributes with Python expressions.

```xml
<!-- REQUIRED in v17+ -->
<field name="partner_id"
       invisible="state == 'draft'"
       readonly="state != 'draft'"
       required="type == 'customer'"/>

<button name="action"
        invisible="state != 'draft'"/>

<group invisible="not show_details">
    <field name="detail"/>
</group>
```

### Expression Conversion Table

| attrs Domain | v17+ Expression |
|--------------|-----------------|
| `[('field', '=', 'value')]` | `field == 'value'` |
| `[('field', '!=', 'value')]` | `field != 'value'` |
| `[('field', '=', True)]` | `field` |
| `[('field', '=', False)]` | `not field` |
| `[('field', 'in', ['a','b'])]` | `field in ('a', 'b')` |
| `[('field', '>', 0)]` | `field > 0` |
| `['&', A, B]` | `A and B` |
| `['|', A, B]` | `A or B` |

### Complex Expressions
```xml
<!-- AND condition -->
<field name="x" invisible="state == 'draft' and not is_manager"/>

<!-- OR condition -->
<field name="x" invisible="state == 'done' or state == 'cancel'"/>

<!-- Using 'in' for multiple states -->
<field name="x" invisible="state in ('done', 'cancelled')"/>

<!-- Parent access in One2many -->
<field name="x" invisible="parent.state != 'draft'"/>

<!-- Context access -->
<field name="x" invisible="context.get('hide_field')"/>
```

## Tree/List View (v17+ Syntax)

### Advanced Tree
```xml
<tree string="My Models"
      decoration-danger="state == 'cancel'"
      decoration-warning="state == 'draft'"
      decoration-success="state == 'done'"
      default_order="date desc">
    <field name="sequence" widget="handle"/>
    <field name="name"/>
    <field name="partner_id"/>
    <field name="date"/>
    <field name="state" widget="badge"
           decoration-success="state == 'done'"
           decoration-info="state == 'confirmed'"
           decoration-warning="state == 'draft'"/>
    <field name="amount" sum="Total"/>
    <field name="company_id" column_invisible="True"/>
    <field name="internal_notes" optional="hide"/>
</tree>
```

### Column Visibility
```xml
<!-- Hide column completely -->
<field name="internal_id" column_invisible="True"/>

<!-- Optional column (user can show/hide) -->
<field name="notes" optional="hide"/>
<field name="important" optional="show"/>

<!-- Conditional column visibility -->
<field name="cost" column_invisible="not context.get('show_cost')"/>
```

## Search View

```xml
<search string="Search My Model">
    <field name="name"/>
    <field name="partner_id"/>
    <field name="user_id"/>

    <separator/>
    <filter name="draft" string="Draft"
            domain="[('state', '=', 'draft')]"/>
    <separator/>
    <filter name="my_records" string="My Records"
            domain="[('user_id', '=', uid)]"/>

    <group expand="0" string="Group By">
        <filter name="group_state" string="Status"
                context="{'group_by': 'state'}"/>
        <filter name="group_date" string="Date"
                context="{'group_by': 'date:month'}"/>
    </group>

    <!-- Search Panel (left sidebar) -->
    <searchpanel>
        <field name="state" icon="fa-filter" enable_counters="1"/>
        <field name="category_id" icon="fa-folder" enable_counters="1"/>
    </searchpanel>
</search>
```

## Form View Example

```xml
<form string="My Model">
    <header>
        <button name="action_confirm" type="object" string="Confirm"
                class="btn-primary" invisible="state != 'draft'"/>
        <field name="state" widget="statusbar" statusbar_visible="draft,confirmed,done"/>
    </header>
    <sheet>
        <div class="oe_button_box" name="button_box">
            <button name="action_view_lines" type="object" class="oe_stat_button" icon="fa-list">
                <field name="line_count" widget="statinfo" string="Lines"/>
            </button>
        </div>
        <widget name="web_ribbon" title="Archived" bg_color="bg-danger" invisible="active"/>
        <div class="oe_title">
            <h1><field name="name" placeholder="Name"/></h1>
        </div>
        <group>
            <group>
                <field name="partner_id" readonly="state != 'draft'"/>
                <field name="date"/>
            </group>
            <group>
                <field name="company_id" groups="base.group_multi_company"/>
                <field name="user_id" widget="many2one_avatar_user"/>
            </group>
        </group>
        <notebook>
            <page string="Lines" name="lines">
                <field name="line_ids">
                    <tree editable="bottom">
                        <field name="sequence" widget="handle"/>
                        <field name="name"/>
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
```

## Common Widgets (v17)

| Widget | Field Types | Purpose |
|--------|-------------|---------|
| `statusbar` | Selection | Status bar display |
| `badge` | Selection | Colored badge |
| `priority` | Selection | Star rating |
| `many2one_avatar_user` | Many2one | User avatar |
| `many2many_tags` | Many2many | Tag chips |
| `monetary` | Float/Monetary | Currency display |
| `handle` | Integer | Drag handle |
| `boolean_toggle` | Boolean | Toggle switch |
| `image` | Binary | Image display |
