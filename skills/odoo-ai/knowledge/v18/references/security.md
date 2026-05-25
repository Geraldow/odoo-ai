---
title: Odoo 18 — Security Reference
domain: security
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Security Reference

## Access Control List (`ir.model.access.csv`)

File path: `security/ir.model.access.csv`

| Column | Description |
| :--- | :--- |
| `id` | External ID (unique). |
| `name` | Descriptive name. |
| `model_id:id` | Target model (`model_model_name`). |
| `group_id:id` | Group that gets access. If empty, all users. |
| `perm_read` | `1` to allow read access. |
| `perm_write` | `1` to allow write access. |
| `perm_create` | `1` to allow create access. |
| `perm_unlink` | `1` to allow delete access. |

## Record Rules (`ir.rule`)

Used for dynamic filtering of records based on domains.

```xml
<record id="rule_own_documents" model="ir.rule">
    <field name="name">Own Documents Only</field>
    <field name="model_id" ref="model_my_custom_model"/>
    <field name="domain_force">[('user_id', '=', uid)]</field>
    <field name="groups" eval="[(4, ref('base.group_user'))]"/>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="True"/>
    <field name="perm_create" eval="True"/>
    <field name="perm_unlink" eval="True"/>
</record>
```

### Domain Syntax for Rules
- `uid`: Current user ID.
- `user`: Current user recordset (`res.users`).
- `company_id` / `company_ids`: Current company / allowed companies.

## Security Groups Inheritance
```xml
<record id="group_manager" model="res.groups">
    <field name="name">Manager</field>
    <field name="category_id" ref="base.module_category_accounting"/>
    <field name="implied_ids" eval="[(4, ref('group_user'))]"/>
</record>
```

## Programmatic Security

### Sudo
Bypasses all access rules and record rules.
```python
# Returns a new recordset as Superuser
admin_record = self.sudo()
```

### Manual Checks
```python
# Check if current user has permission
self.check_access_rights('write')
self.check_access_rule('read')
```
