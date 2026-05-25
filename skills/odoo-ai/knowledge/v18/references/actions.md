---
title: Odoo 18 — Actions Reference
domain: actions
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Actions Reference

## Window Actions (`ir.actions.act_window`)

Used to open views in the web client.

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `name` | `str` | Name of the action (shown in breadcrumbs). |
| `res_model` | `str` | Target model. |
| `view_mode` | `str` | Comma-separated view types (e.g., `list,form,kanban`). |
| `domain` | `list` | Filters records to show. |
| `context` | `dict` | Context for target views. |
| `target` | `str` | `current` (same window) or `new` (dialog/popup). |
| `res_id` | `int` | ID of a specific record (for form views). |
| `binding_model_id` | `ref` | Model where this action appears in "Action" menu. |

```xml
<record id="action_my_model" model="ir.actions.act_window">
    <field name="name">My Records</field>
    <field name="res_model">my.model</field>
    <field name="view_mode">list,form</field>
    <field name="domain">[('state', '=', 'active')]</field>
    <field name="context">{'search_default_my_records': 1}</field>
</record>
```

## Server Actions (`ir.actions.server`)

Executes Python code on the server.

| State | Description |
| :--- | :--- |
| `code` | Executes Python code provided in `code` field. |
| `object_create` | Creates a record of a target model. |
| `object_write` | Updates values on current record. |
| `action_delayed` | Schedules another action. |

```xml
<record id="action_mark_done" model="ir.actions.server">
    <field name="name">Mark Done</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="binding_model_id" ref="model_my_model"/>
    <field name="state">code</field>
    <field name="code">
        records.action_done()
    </field>
</record>
```

## URL Actions (`ir.actions.act_url`)
```xml
<record id="action_google" model="ir.actions.act_url">
    <field name="name">Google</field>
    <field name="url">https://www.google.com</field>
    <field name="target">new</field>
</record>
```

## Client Actions (`ir.actions.client`)
Triggers a JavaScript component/action.
- `tag`: The internal ID of the client-side component.
- `params`: Arguments passed to the component.
