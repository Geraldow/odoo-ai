---
title: Odoo 16 — Security Guide
domain: security
version: 16.0
edition: community
source: legacy
status: active
---

# Odoo 16 — Security Guide

## Purpose
Access rules, record rules, and group definitions for Odoo 16.

## Security Groups (v16 Syntax)

```xml
<record id="module_category_custom" model="ir.module.category">
    <field name="name">Custom Module</field>
    <field name="sequence">100</field>
</record>

<record id="group_custom_user" model="res.groups">
    <field name="name">User</field>
    <field name="category_id" ref="module_category_custom"/>
</record>

<record id="group_custom_manager" model="res.groups">
    <field name="name">Manager</field>
    <field name="category_id" ref="module_category_custom"/>
    <field name="implied_ids" eval="[(4, ref('group_custom_user'))]"/>
</record>
```

## Record Rules (v16 Syntax)

### Multi-Company Rule
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

## View Security (attrs Deprecated)

In Odoo 16, prefer direct attributes over `attrs` to prepare for v17.

```xml
<form>
    <sheet>
        <group>
            <field name="name"/>
            <!-- Recommended v16 Pattern -->
            <field name="manager_notes"
                   invisible="state == 'draft'"
                   groups="custom_module.group_manager"/>
            
            <button name="action_confirm"
                    string="Confirm"
                    type="object"
                    invisible="state != 'draft'"/>
        </group>
    </sheet>
</form>
```

## Security with Command Class

The `Command` class improves security by making operations more explicit and readable.

```python
from odoo import Command

def action_update_lines(self):
    """v16: Use Command class for x2many operations."""
    self.write({
        'line_ids': [
            Command.create({'name': 'New Line'}),
            Command.update(line_id, {'name': 'Updated'}),
            Command.delete(line_id),
            Command.clear(),
        ]
    })
```

## Migration from v15 to v16 Security

| Component | v15 | v16 | Migration Required |
|-----------|-----|-----|-------------------|
| x2many operations | Tuple syntax | `Command` class | Recommended |
| View visibility | `attrs` | `attrs` (deprecated) | Prepare for v17 |
| @api.model_create_multi | Optional | Recommended | Recommended |

## v16 Security Checklist

- [ ] All models have `ir.model.access.csv` entries.
- [ ] Record rules use `company_ids` for multi-company.
- [ ] Prefer direct `invisible` attribute over `attrs`.
- [ ] Use `Command` class for x2many security operations.
- [ ] Use `tracking=True` instead of `track_visibility`.
