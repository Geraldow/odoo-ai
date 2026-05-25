---
title: Odoo 19 — Actions Reference
domain: actions
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Actions Reference

## Window Actions (`ir.actions.act_window`)

The primary way to display models in the web client.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `name` | `str` | Display name for breadcrumbs. |
| `res_model` | `str` | Target model. |
| `view_mode` | `str` | Comma-separated views: `list,form,kanban,pivot,graph`. |
| `domain` | `list` | Domain filter for the records. |
| `context` | `dict` | Context passed to the views. |
| `target` | `str` | `current` (main area) or `new` (popup). |
| `binding_model_id`| `ref` | Makes action appear in the "Action" menu of a model. |

```xml
<record id="action_my_custom_model" model="ir.actions.act_window">
    <field name="name">Custom Records</field>
    <field name="res_model">my.custom.model</field>
    <field name="view_mode">list,form</field>
    <field name="domain">[('active', '=', True)]</field>
    <field name="context">{'search_default_my_records': 1}</field>
</record>
```

## Server Actions (`ir.actions.server`)

Executes Python logic from the UI or automation.

| State | Purpose |
| :--- | :--- |
| `code` | Executes Python code string. |
| `object_create` | Creates a new record. |
| `object_write` | Updates the current record. |

```xml
<record id="action_validate_all" model="ir.actions.server">
    <field name="name">Validate Records</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="binding_model_id" ref="model_my_model"/>
    <field name="state">code</field>
    <field name="code">
        records.action_validate()
    </field>
</record>
```

## API Documentation Action (`api_doc`)
Odoo 19 introduces a built-in documentation tool accessible via the `/doc` route, providing a Swagger-like interface for your custom model's methods.

## Client Actions (`ir.actions.client`)
Triggers specific OWL components or JavaScript functions.
- `tag`: The identifier of the client-side component (e.g., `my_module.main_view`).
- `params`: Payload for the JS component.

## UI Logic: Rotting Registries
Odoo 19 actions can trigger "rotting" visual indicators for stale records in specific Kanban/List views, highlighting them if they haven't been processed within a defined timeframe.
