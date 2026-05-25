---
title: Odoo 16 — Version Notes
domain: changelog
version: 16.0
edition: community
source: legacy
status: active
---

# Odoo 16 — Version Notes

## Purpose
Breaking changes, new APIs, and migration notes from Odoo 15 to 16 (OWL 2, spreadsheet).

## Key Changes from v15

### Command Class Introduced
```python
from odoo.fields import Command

# NEW v16 syntax
line_ids = [
    Command.create({'name': 'Line 1'}),
    Command.update(id, {'name': 'Updated'}),
    Command.delete(id),
    Command.set([id1, id2]),
]
```

### attrs DEPRECATED
```xml
<!-- v16 RECOMMENDED -->
<field name="partner_id"
       invisible="state == 'draft'"/>
```

### OWL 2.x
Complete rewrite from OWL 1.x. Uses ES modules and direct imports.

## Technical Stack
- Python 3.8+ (3.10 recommended)
- PostgreSQL 12+
- OWL 2.x framework
- ES modules (`/** @odoo-module **/`)

## Preparing for v17 Upgrade

- **Critical: attrs REMOVED in v17** - Migrate to inline expressions now.
- **Critical: create_multi MANDATORY in v17** - Update all `create` methods.
- **Python 3.10+ required in v17**.
