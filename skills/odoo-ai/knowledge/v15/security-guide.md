---
title: Odoo 15 — Security Guide
domain: security
version: 15.0
edition: community
source: legacy
status: active
---

# Odoo 15 — Security Guide

## Purpose
Access rules, record rules, and group definitions for Odoo 15.

## Security Groups (v15 Syntax)

```xml
<record id="group_custom_user" model="res.groups">
    <field name="name">User</field>
    <field name="category_id" ref="base.module_category_hidden"/>
</record>

<record id="group_custom_manager" model="res.groups">
    <field name="name">Manager</field>
    <field name="implied_ids" eval="[(4, ref('group_custom_user'))]"/>
</record>
```

## Record Rules (v15 Syntax)

```xml
<record id="rule_custom_model_company" model="ir.rule">
    <field name="name">Custom Model: Multi-Company</field>
    <field name="model_id" ref="model_custom_model"/>
    <field name="global" eval="True"/>
    <field name="domain_force">[
        '|',
        ('company_id', '=', False),
        ('company_id', 'in', company_ids)
    ]</field>
</record>
```

## View Security (v15 attrs)

```xml
<field name="internal_notes"
       attrs="{'invisible': [('state', '=', 'draft')]}"
       groups="custom_module.group_manager"/>
```

## Model Security (v15 Patterns)

```python
from odoo import api, fields, models, _
from odoo.exceptions import AccessError

class SecureModel(models.Model):
    _name = 'custom.secure'

    name = fields.Char(tracking=True) # v15: tracking replaces track_visibility
    
    def action_sensitive(self):
        if not self.env.user.has_group('custom_module.group_manager'):
            raise AccessError(_("Only managers can perform this action."))
```

## Key Differences from v14

| Feature | v14 | v15 |
|---------|-----|-----|
| Field tracking | `track_visibility='onchange'` | `tracking=True` |
| @api.multi | Deprecated | Removed |
| OWL | Not available | OWL 1.x introduced |
