---
title: Odoo 14 — Security Guide
domain: security
version: 14.0
edition: community
source: legacy
status: active
---

# Odoo 14 — Security Guide

## Security Groups Definition
Groups are defined in XML files, usually under `security/security.xml`.

```xml
<record id="module_category_custom" model="ir.module.category">
    <field name="name">Custom Module</field>
    <field name="sequence">100</field>
</record>

<record id="group_custom_user" model="res.groups">
    <field name="name">User</field>
    <field name="category_id" ref="module_category_custom"/>
    <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
</record>

<record id="group_custom_manager" model="res.groups">
    <field name="name">Manager</field>
    <field name="category_id" ref="module_category_custom"/>
    <field name="implied_ids" eval="[(4, ref('group_custom_user'))]"/>
</record>
```

## Access Rights (CSV)
Located in `security/ir.model.access.csv`. Defines CRUD permissions for groups.

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_my_model_user,my.model.user,model_my_model,group_custom_user,1,1,1,0
access_my_model_manager,my.model.manager,model_my_model,group_custom_manager,1,1,1,1
```

## Record Rules
Record rules restrict access based on record values (domains).

```xml
<record id="rule_my_model_own_records" model="ir.rule">
    <field name="name">My Model: User Own Records</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('group_custom_user'))]"/>
</record>

<record id="rule_my_model_multi_company" model="ir.rule">
    <field name="name">My Model: Multi-Company</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="global" eval="True"/>
    <field name="domain_force">['|', ('company_id', '=', False), ('company_id', 'in', company_ids)]</field>
</record>
```

## Model-Level Security
In Odoo 14, field tracking uses `track_visibility`.

```python
class MyModel(models.Model):
    _name = 'my.model'
    _inherit = ['mail.thread']

    name = fields.Char(track_visibility='onchange')
    internal_notes = fields.Text(groups='my_module.group_custom_manager')

    def action_manager_only(self):
        if not self.env.user.has_group('my_module.group_custom_manager'):
            raise AccessError(_("Only managers can perform this action."))
        # action logic...
```

## View-Level Security
Use `groups` attribute on fields, buttons, or pages in XML views.

```xml
<button name="action_approve" groups="my_module.group_custom_manager" attrs="{'invisible': [('state', '!=', 'draft')]}"/>
<page name="internal" string="Internal Details" groups="my_module.group_custom_manager">
    <field name="secret_info"/>
</page>
```

## v14 Checklist
- [ ] Ensure all models have entries in `ir.model.access.csv`.
- [ ] Define multi-company rules if `company_id` is present.
- [ ] Use `track_visibility` for field change history in the chatter.
- [ ] Apply `groups` attribute to sensitive fields in views.
