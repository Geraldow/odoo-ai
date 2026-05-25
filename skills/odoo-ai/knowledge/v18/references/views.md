---
title: Odoo 18 — Views Reference
domain: views
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Views Reference

## Common View Attributes

| Attribute | Description |
| :--- | :--- |
| `name` | Informative name of the view. |
| `model` | Target model for the view. |
| `arch` | XML structure of the view. |
| `priority` | Order of resolution (lower is higher priority). |

## Form View (`form`)
```xml
<form string="Model Label">
    <header>
        <button name="action_do_something" type="object" string="Execute" class="oe_highlight"/>
        <field name="state" widget="statusbar"/>
    </header>
    <sheet>
        <group>
            <group>
                <field name="name"/>
                <field name="partner_id" options="{'no_create': True}"/>
            </group>
            <group>
                <field name="date"/>
            </group>
        </group>
        <notebook>
            <page string="Details" name="details">
                <field name="line_ids"/>
            </page>
        </notebook>
    </sheet>
    <chatter/> <!-- Requires mail inheritance -->
</form>
```

## List View (`list` / `tree`)
*Note: In Odoo 18, `tree` is legacy, `list` is preferred, though both work.*
```xml
<list string="Model List" decoration-info="state == 'draft'" multi_edit="1">
    <field name="name"/>
    <field name="partner_id" optional="show"/>
    <field name="amount" sum="Total"/>
    <field name="state" widget="badge"/>
</list>
```

## Kanban View (`kanban`)
```xml
<kanban default_group_by="state" quick_create="false">
    <field name="color"/>
    <templates>
        <t t-name="card">
            <div class="oe_kanban_global_click">
                <field name="name" class="fw-bold"/>
                <field name="partner_id"/>
            </div>
        </t>
    </templates>
</kanban>
```

## Search View (`search`)
```xml
<search>
    <field name="name" string="Name or Description" filter_domain="['|', ('name', 'ilike', self), ('description', 'ilike', self)]"/>
    <field name="partner_id"/>
    <filter name="my_records" string="My Records" domain="[('user_id', '=', uid)]"/>
    <group expand="0" string="Group By">
        <filter name="group_by_partner" string="Partner" context="{'group_by': 'partner_id'}"/>
    </group>
</search>
```

## Pivot & Graph Views
```xml
<!-- Pivot -->
<pivot string="Analysis">
    <field name="partner_id" type="row"/>
    <field name="date" interval="month" type="col"/>
    <field name="amount" type="measure"/>
</pivot>

<!-- Graph -->
<graph string="Analysis" type="bar" sample="1">
    <field name="partner_id"/>
    <field name="amount" type="measure"/>
</graph>
```
