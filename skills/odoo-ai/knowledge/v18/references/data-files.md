---
title: Odoo 18 — Data Files Reference
domain: data
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Data Files Reference

Data files are used to populate the database with initial configuration, demo data, and security rules.

## XML Structure

### The `record` Tag
Used to create or update a database record.

```xml
<record id="xml_id_name" model="res.partner">
    <field name="name">Standard Name</field>
    <field name="email">info@example.com</field>
</record>
```

### External IDs (XML IDs)
Format: `module_name.xml_id`. They allow referencing records across different files or modules.
Stored in the `ir.model.data` table.

### `noupdate="1"`
Used inside a `<odoo><data>` tag to prevent records from being overwritten during module updates.

```xml
<odoo>
    <data noupdate="1">
        <record id="my_config" model="my.model">
            <field name="value">Initial Value</field>
        </record>
    </data>
</odoo>
```

## Special Tags

### `function`
Calls a method on a model during installation/update.

```xml
<function model="res.users" name="_set_random_password">
    <value eval="[ref('base.user_admin')]"/>
</function>
```

### `delete`
Removes a record from the database.

```xml
<delete model="ir.ui.view" id="module.view_id_to_delete"/>
```

### `menuitem`
Short-cut for creating `ir.ui.menu` records.

```xml
<menuitem id="menu_my_root" name="My App" sequence="10"/>
<menuitem id="menu_my_child" name="Dashboard" parent="menu_my_root" action="action_my_view"/>
```

## CSV Data Files
Useful for large datasets (e.g., zip codes, product categories).
Filename format: `model.name.csv`.
Header row must match field names.

```csv
"id","name","email"
"partner_1","John Doe","john@example.com"
"partner_2","Jane Smith","jane@example.com"
```

## Load Order
Files are loaded in the order they appear in the `data` section of `__manifest__.py`. Dependencies must be loaded before the files that reference them.
