---
title: Odoo 17 — Security Guide
domain: security
version: 17.0
edition: community
source: legacy
status: active
---

# Odoo 17 — Security Guide

## Version 17.0 Requirements

- **Python**: 3.10+ required
- **Key Changes**: `attrs` removed from views, `@api.model_create_multi` mandatory
- **Record Rules**: Use `company_ids` or `allowed_company_ids` (v17+ recommendation)

## Security Groups (v17 Syntax)

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

## Record Rules (v17 Syntax)

### Multi-Company Rule
```xml
<!-- v17: Use company_ids for multi-company -->
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

### User Own Records Rule
```xml
<record id="rule_custom_model_user_own" model="ir.rule">
    <field name="name">Custom Model: User Own Records</field>
    <field name="model_id" ref="model_custom_model"/>
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('group_custom_user'))]"/>
</record>
```

## Model Security (v17 Patterns)

```python
from odoo import api, fields, models, _
from odoo.exceptions import AccessError

class SecureModel(models.Model):
    _name = 'custom.secure'
    _description = 'Secure Model'

    name = fields.Char(string='Name', required=True)
    company_id = fields.Many2one('res.company', default=lambda self: self.env.company)
    user_id = fields.Many2one('res.users', default=lambda self: self.env.user)

    @api.model_create_multi
    def create(self, vals_list):
        # v17: @api.model_create_multi is mandatory
        return super().create(vals_list)

    def action_sensitive_operation(self):
        """Check permissions before sensitive operations."""
        if not self.env.user.has_group('custom_module.group_manager'):
            raise AccessError(_("Only managers can perform this action."))
        # ... logic
```

## View Security (v17 Syntax - NO attrs)

### Field and Button Visibility
Use direct `invisible` attribute with Python expressions.

```xml
<form>
    <header>
        <button name="action_approve" string="Approve" type="object"
                groups="custom_module.group_manager"
                invisible="state != 'pending'"/>
    </header>
    <sheet>
        <group>
            <field name="name"/>
            <!-- Manager-only field -->
            <field name="internal_notes" groups="custom_module.group_manager"/>
            <!-- Conditional visibility based on group -->
            <field name="secret_field" invisible="not user_has_groups('custom_module.group_manager')"/>
        </group>
    </sheet>
</form>
```

## Migration Notes (v16 -> v17)

### attrs REMOVED
The `attrs` attribute is completely removed in v17.

**v16 Pattern (BREAKS in v17):**
```xml
<field name="f" attrs="{'invisible': [('state', '=', 'draft')]}"/>
```

**v17 Pattern (REQUIRED):**
```xml
<field name="f" invisible="state == 'draft'"/>
```

### Expression Conversion
| v16 Domain | v17 Expression |
|------------|----------------|
| `[('f', '=', 'v')]` | `f == 'v'` |
| `[('f', '!=', 'v')]` | `f != 'v'` |
| `['&', A, B]` | `A and B` |
| `['|', A, B]` | `A or B` |
| `[('f', 'in', ['a', 'b'])]` | `f in ('a', 'b')` |

## v17 Security Checklist

- [ ] All models have `ir.model.access.csv` entries
- [ ] Record rules use `company_ids` or `allowed_company_ids`
- [ ] Views use direct `invisible`/`readonly`/`required` (NO `attrs`)
- [ ] Use `@api.model_create_multi` for create methods
- [ ] SQL queries use parameterized syntax
- [ ] Button visibility uses `invisible` with Python expression
