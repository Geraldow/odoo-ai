---
title: ACL and Record Rule Patterns
domain: security
version: 18.0
edition: both
source: native
status: complete
priority: P1
---

# ACL and Record Rule Patterns

## ir.model.access.csv Format

Every persistent model needs an ACL row.

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_my_model_user,my.model user,model_my_model,base.group_user,1,0,0,0
```

Columns:
- `id`: unique XML ID for the ACL row.
- `name`: readable label.
- `model_id:id`: generated model XML ID, usually `model_module_model`.
- `group_id:id`: group that receives the permissions.
- `perm_*`: `1` or `0`.

## Minimal Groups

Start with the smallest useful access:
- `base.group_user`: internal users, usually read-only first.
- `base.group_system`: administrators.
- Module groups: business-specific roles such as manager, approver, or reviewer.

Do not grant write/create/unlink broadly unless the business process requires it.

## Multi-Company Record Rule

Use company-aware domains when records belong to a company.

```xml
<record id="my_model_company_rule" model="ir.rule">
    <field name="name">My Model: company isolation</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="domain_force">[('company_id', 'in', user.company_ids.ids)]</field>
    <field name="groups" eval="[(4, ref('base.group_user'))]"/>
</record>
```

If `company_id` can be empty by design, explicitly decide whether shared records
are allowed and include that case in the domain.

## Owner Record Rule

Use owner rules for records assigned to a specific user.

```xml
<field name="domain_force">[('user_id', '=', user.id)]</field>
```

For portal/customer records, compare partner ownership instead of internal user
assignment.

## Least Privilege Workflow

1. Add read ACL for the smallest group.
2. Add write/create only for roles that execute the process.
3. Add unlink only when deletion is a real business operation.
4. Add record rules for company, owner, or team isolation.
5. Verify with a non-admin user before release.
