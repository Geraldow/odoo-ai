---
title: Odoo 18 — Security Guide
domain: security
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Security Guide

## Purpose
Access rules, record rules, group definitions, and sudo() patterns for Odoo 18.

## Security Groups and Categories
Define the hierarchy of user roles in `security/your_module_security.xml`.

```xml
<odoo>
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
</odoo>
```

## Access Rights (ACLs)
Defined in `security/ir.model.access.csv`.

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_my_model_user,my.model.user,model_my_model,group_custom_user,1,1,1,0
access_my_model_manager,my.model.manager,model_my_model,group_custom_manager,1,1,1,1
```

## Record Rules (v18 Syntax)

### Multi-Company Rules
In Odoo 18, use `allowed_company_ids` instead of the legacy `company_ids`.

```xml
<record id="rule_my_model_multi_company" model="ir.rule">
    <field name="name">My Model: Multi-Company</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="global" eval="True"/>
    <field name="domain_force">[
        '|', ('company_id', '=', False), ('company_id', 'in', allowed_company_ids)
    ]</field>
</record>
```

### Personal Records Rule
```xml
<record id="rule_my_model_personal" model="ir.rule">
    <field name="name">My Model: Personal Records</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="domain_force">[('user_id', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('group_custom_user'))]"/>
</record>
```

## Model-Level Security Patterns

### Automatic Company Consistency
```python
class MyModel(models.Model):
    _name = 'my.model'
    _check_company_auto = True  # Mandatory for automated checks

    company_id = fields.Many2one('res.company', required=True)
    partner_id = fields.Many2one(
        'res.partner',
        check_company=True,  # Ensures partner belongs to the same company
    )
```

### Secure Method Implementation
```python
from odoo.exceptions import AccessError

def action_confirm(self):
    if not self.env.user.has_group('my_module.group_custom_manager'):
        raise AccessError(_("Only managers can confirm these records."))
    # ... logic
```

### Secure SQL Builder
Use the `SQL()` builder to prevent injection and handle identifiers correctly.

```python
from odoo.tools import SQL

def _get_raw_data(self):
    query = SQL(
        "SELECT id FROM %s WHERE company_id = %s",
        SQL.identifier(self._table),
        self.env.company.id
    )
    self.env.cr.execute(query)
    return self.env.cr.dictfetchall()
```

## Field and View Security

### Field-Level Groups
```python
secret_code = fields.Char(groups='my_module.group_custom_manager')
```

### View-Level Visibility
In v18, use `invisible` or `groups` directly on buttons/fields.

```xml
<!-- Button visible only to managers -->
<button name="action_reset" type="object" groups="my_module.group_custom_manager"/>

<!-- Field invisible based on group -->
<field name="admin_notes" invisible="not user_has_groups('my_module.group_custom_manager')"/>
```

## Audit Trail Pattern
For highly sensitive models, implement manual audit logging by overriding `create`, `write`, and `unlink` and using `sudo()`.

```python
def write(self, vals):
    res = super().write(vals)
    self.env['audit.log'].sudo().create({
        'res_model': self._name,
        'res_id': self.id,
        'changes': str(vals),
    })
    return res
```

## v18 Security Checklist
- [ ] Every model has an entry in `ir.model.access.csv`.
- [ ] Multi-company models have `_check_company_auto = True`.
- [ ] Record rules use `allowed_company_ids`.
- [ ] Relational fields use `check_company=True`.
- [ ] Buttons with sensitive logic have `groups` attributes.
- [ ] Raw SQL queries use the `SQL()` builder.
- [ ] `sudo()` is only used when strictly necessary for technical bypasses.

## AI Agent Instructions
When generating Odoo 18.0 security:
1. **Always** include `_check_company_auto = True` in multi-company models.
2. **Use** `allowed_company_ids` for multi-company record rules.
3. **Set** `check_company=True` on Many2one fields to company-dependent models.
4. **Define** `groups` on fields that should only be seen by specific roles.
5. **Use** `SQL()` builder for any database-level operations.
6. **Ensure** `ir.model.access.csv` is correctly mapped for all new models.
7. **Never** use `attrs` in XML; use direct attributes like `invisible` or `readonly`.
