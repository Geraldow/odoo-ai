---
title: Odoo 19 — Security Reference
domain: security
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Security Reference

## Access Control List (`ir.model.access.csv`)

Location: `security/ir.model.access.csv`

| Column | Description |
| :--- | :--- |
| `id` | Unique External ID. |
| `name` | Descriptive name of the rule. |
| `model_id:id` | Target model (format: `model_model_name`). |
| `group_id:id` | Group receiving access (Empty = All Users). |
| `perm_read` | `1` to allow Reading. |
| `perm_write` | `1` to allow Writing. |
| `perm_create` | `1` to allow Creating. |
| `perm_unlink` | `1` to allow Deleting. |

## Record Rules (`ir.rule`)

Used for dynamic row-level security.

```xml
<record id="rule_personal_leads" model="ir.rule">
    <field name="name">Personal Leads Only</field>
    <field name="model_id" ref="model_crm_lead"/>
    <field name="domain_force">[('user_id', '=', uid)]</field>
    <field name="groups" eval="[(4, ref('base.group_user'))]"/>
    <field name="perm_read" eval="True"/>
    <field name="perm_write" eval="True"/>
</record>
```

### New Domain Logic in v19
- **`any!` Operator:** Use `any!` in domains for more efficient One2many/Many2many existence checks in rules.
- **Global Rules:** Rules without groups apply to all users (including Superuser unless bypassed).

## Security Groups
```xml
<record id="group_auditor" model="res.groups">
    <field name="name">Auditor</field>
    <field name="category_id" ref="base.module_category_hidden"/>
    <field name="implied_ids" eval="[(4, ref('base.group_user'))]"/>
</record>
```

## Programmatic Security (v19 Updates)

### Unified Access Check
Odoo 19 promotes `check_access` as the primary method to validate permissions.

```python
# Check if user can edit the record
self.check_access('write')
```

### Sudo & Sudoed Environments
```python
# Bypass all security for specific operations
records = self.sudo().search([])

# Better practice: Switch user context
records_as_manager = self.with_user(manager_id).search([])
```

### Multi-Company Security
Always include `company_id` checks if the model is multi-company.
```python
_check_company_auto = True
company_id: 'ResCompany' = fields.Many2one('res.company', required=True, default=lambda self: self.env.company)
```
