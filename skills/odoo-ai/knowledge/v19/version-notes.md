---
title: Odoo 19 — Version Notes
domain: changelog
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Version Notes

## Purpose
Breaking changes, new APIs, and migration notes from Odoo 18 to 19.

## Summary of Breaking Changes

| Category | Change | Impact |
|----------|--------|--------|
| **SQL** | `SQL()` builder **REQUIRED** for all queries | **CRITICAL** |
| **Constraints** | `models.Constraint()` replaces `_sql_constraints` list | High |
| **res.users** | `groups_id` cannot be set during `create()` | High |
| **OWL** | OWL 3.x replaces OWL 2.x (stricter props) | High |
| **Python** | Python 3.12+ features actively used / required | Medium |
| **Types** | Type hints strongly required for methods | High |
| **Multi-Company**| `_check_company_auto = True` strictly enforced | High |

## Major Updates

### 1. The `SQL()` Builder
Direct string execution via `cr.execute()` is fully disabled. You must import `odoo.tools.SQL` and construct queries safely. 

### 2. Constraint Declarations
The `_sql_constraints` array no longer functions. Each constraint must be defined as a standalone model attribute calling `models.Constraint(sql, message)`.

### 3. User Creation Security
Setting groups via `groups_id` when creating a user (`res.users.create()`) is blocked for security hardening. Users must be created first, and then assigned to the group explicitly.

```python
# Create user
user = self.env['res.users'].create({'name': 'Test', 'login': 'test'})
# Assign group
self.env.ref('base.group_portal').write({'users': [(4, user.id)]})
```
