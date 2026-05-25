---
title: Odoo 19 — Views Reference
domain: views
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Views Reference

## Major Changes in v19
- **Terminolgy:** `<tree>` is officially replaced by **`<list>`**.
- **Dynamic Attributes:** `attrs` and `states` are removed. Use inline attributes with Python expressions.
- **Kanban:** `t-name="kanban-box"` is replaced by **`t-name="card"`**.

## List View (`list`)
Formerly known as `tree` view.
```xml
<list string="Records" decoration-info="state == 'draft'" multi_edit="1">
    <field name="name"/>
    <field name="partner_id" optional="show"/>
    <field name="amount" sum="Total"/>
    <field name="state" widget="badge" decoration-success="state == 'done'"/>
</list>
```

## Form View (`form`)
`attrs` are now direct attributes.
```xml
<form>
    <header>
        <button name="action_confirm" type="object" string="Confirm" 
                invisible="state != 'draft'" class="oe_highlight"/>
        <field name="state" widget="statusbar"/>
    </header>
    <sheet>
        <group>
            <field name="partner_id" readonly="state == 'done'" required="True"/>
            <field name="date" invisible="not partner_id"/>
        </group>
    </sheet>
</form>
```

## Kanban View (`kanban`)
Uses the new `<card>` structure and supports multi-selection.
```xml
<kanban default_group_by="state" sample="1">
    <field name="color"/>
    <templates>
        <t t-name="card">
            <div class="oe_kanban_global_click">
                <div class="d-flex justify-content-between">
                    <field name="name" class="fw-bold"/>
                    <field name="priority" widget="priority"/>
                </div>
                <div>
                    <field name="partner_id"/>
                </div>
            </div>
        </t>
    </templates>
</kanban>
```

## Search View (`search`)
```xml
<search>
    <field name="name" filter_domain="['|', ('name', 'ilike', self), ('ref', 'ilike', self)]"/>
    <filter name="draft" string="Draft" domain="[('state', '=', 'draft')]"/>
    <group expand="0" string="Group By">
        <filter name="group_by_partner" string="Partner" context="{'group_by': 'partner_id'}"/>
    </group>
</search>
```

## Dynamic Attribute Mapping

| Old Odoo (<17) | Odoo 19 |
| :--- | :--- |
| `attrs="{'invisible': [('s', '=', 'v')]}"` | `invisible="s == 'v'"` |
| `attrs="{'readonly': [('s', '=', 'v')]}"` | `readonly="s == 'v'"` |
| `attrs="{'required': [('s', '=', 'v')]}"` | `required="s == 'v'"` |
| `states="draft,open"` | `invisible="state not in ('draft', 'open')"` |

## QWeb Changes
- `t-raw` is deprecated; use **`t-out`** for security (escapes HTML by default).
- `t-esc` is still used for simple escaping.
