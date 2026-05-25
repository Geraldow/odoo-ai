---
title: Odoo Overview
domain: core
version: 18.0
edition: both
source: odoo-contribute
status: complete
priority: P4
---

# Odoo Architecture Overview

## Stack

Odoo combines:
- Python ORM and business models.
- PostgreSQL persistence.
- XML views and actions.
- QWeb reports/templates.
- OWL frontend components in modern web client areas.
- Security through ACLs, groups, record rules, and field-level groups.

## Module Anatomy

`__manifest__.py` declares identity, dependencies, data files, assets, license,
and version. Odoo loads files in manifest order, so security and base data must
come before views that depend on them.

## Request Flow

```text
UI action -> controller/RPC/model method -> ORM -> PostgreSQL
          -> access checks/rules -> response/view update
```

## Security Layers

1. ACL grants model-level permissions.
2. Record rules filter records.
3. Field groups hide sensitive values.
4. Explicit checks protect business operations.
5. Controller auth and CSRF protect HTTP entry points.

## Development Defaults

- Detect Odoo version from `__manifest__.py`.
- Assume Community unless license is `OEEL-1`.
- Verify Enterprise APIs before using Enterprise-only patterns.
- Keep custom modules small, installable, and reversible.
