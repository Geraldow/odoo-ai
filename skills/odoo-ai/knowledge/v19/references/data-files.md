---
title: Odoo 19 — Data Files Reference
domain: data
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Data Files Reference

Data files in Odoo 19 define the initial state, configuration, and security structure of a module using XML or CSV formats.

## XML Data Definition

### The `<record>` Element
Creates or updates a record in the database.

```xml
<record id="xml_id_identifier" model="res.partner">
    <field name="name">Global Service Inc.</field>
    <field name="category_id" eval="[(4, ref('base.res_partner_category_8'))]"/>
</record>
```

### External IDs (XML IDs)
- **Format**: `module_name.xml_id`.
- **Purpose**: Unique identifiers that allow cross-referencing records without knowing their database integer ID.
- **Storage**: Tracked in the `ir.model.data` table.

### The `noupdate` Attribute
Used to protect records from being reset during module upgrades (e.g., user-configurable settings).

```xml
<odoo>
    <data noupdate="1">
        <record id="custom_config" model="my.model">
            <field name="value">Persistent Data</field>
        </record>
    </data>
</odoo>
```

## Special XML Tags

### `<function>`
Triggers Python method execution during module loading.

```xml
<function model="account.chart.template" name="try_loading">
    <value eval="[ref('my_module.my_l10n_chart')]"/>
</function>
```

### `<delete>`
Removes existing records. Useful for cleaning up data from inherited modules.

```xml
<delete model="ir.ui.view" id="base.view_partner_form_old"/>
```

### `<menuitem>`
A concise shorthand for creating `ir.ui.menu` records.

```xml
<menuitem id="menu_root" name="Operations" sequence="5"/>
<menuitem id="menu_sub" name="Tasks" parent="menu_root" action="action_task_view"/>
```

## CSV Data Files
Ideal for importing large tables of static data (e.g., countries, postal codes, product categories).

- **Filename Pattern**: `model.name.csv` (e.g., `res.country.state.csv`).
- **Header**: Must match the technical names of the fields.

```csv
"id","name","country_id:id"
"state_ny","New York","base.us"
"state_ca","California","base.us"
```

## Loading Order and Dependencies
The `data` section in `__manifest__.py` determines the load order. 
- Records referencing other records (via `ref`) must be loaded AFTER their dependencies.
- Use the `depends` list in the manifest to ensure parent modules are loaded first.
