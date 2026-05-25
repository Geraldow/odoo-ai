---
title: Access Rules Reference
domain: security
version: 18.0
edition: both
source: native
status: complete
priority: P1
---

# Access Rules Reference

## Purpose

Use this reference to choose between model ACLs, record rules, field groups, and
explicit business checks in Odoo modules.

## Layers

| Layer | File / API | Protects | Example |
|---|---|---|---|
| ACL | `security/ir.model.access.csv` | Model-level read/write/create/unlink | Internal users can read a model |
| Record rule | `ir.rule` XML data | Which records a user can see/use | User sees only own company records |
| Field group | `fields.*(groups=...)` | Field visibility/read access | Admin-only token field |
| Explicit check | Python method/controller | Business action boundary | Only manager can approve |

## When To Use ACL

Use ACLs for baseline model permissions. Every persistent `models.Model` should
have at least one ACL entry unless it is intentionally system-only and never
directly accessed by users.

Start conservative:

```csv
access_my_model_user,my.model user,model_my_model,base.group_user,1,0,0,0
```

Then add write/create/unlink only to groups that need those actions.

## When To Use Record Rules

Use record rules when access depends on the record itself:
- `company_id` belongs to one of `user.company_ids`
- `user_id` equals the current user
- team, department, warehouse, or branch membership
- portal partner ownership

Record rules complement ACLs; they do not replace model permissions.

## When To Use Field Groups

Use `groups=` for sensitive fields that should not appear to every user who can
read the record.

```python
internal_note = fields.Text(groups="base.group_system")
```

Do not rely only on hiding fields in XML views; protect the field definition.

## When To Use Explicit Checks

Use Python checks for actions with business meaning:
- approving, cancelling, posting, exporting, sending, reconciling
- operations using `sudo()`
- controller actions receiving IDs from a request

```python
if not self.env.user.has_group("my_module.group_approver"):
    raise AccessError(_("Only approvers can confirm this record."))
```

## Review Checklist

- [ ] New model has ACL.
- [ ] ACL grants least privilege.
- [ ] Record rules cover company/owner isolation when applicable.
- [ ] Sensitive fields have `groups=`.
- [ ] Business actions check groups or ownership before `sudo()`.
