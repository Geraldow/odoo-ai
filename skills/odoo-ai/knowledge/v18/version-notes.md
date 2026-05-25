---
title: Odoo 18 — Version Notes
domain: changelog
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Version Notes

## Purpose
Breaking changes, new APIs, and technical highlights for Odoo 18.

## Release Overview
- **Release Date**: October 2024.
- **Python Version**: 3.11 required, 3.12 recommended.
- **Frontend**: OWL 2.x (enhanced performance and reactivity).
- **Core Focus**: Security (SQL builder), multi-company automation, and performance.

## Major Technical Features (v18)

### 1. Automatic Company Consistency (`_check_company_auto`)
Developers no longer need to write manual Python constraints to ensure that a record's partner, warehouse, or location belongs to the same company as the record itself.
```python
_check_company_auto = True
partner_id = fields.Many2one('res.partner', check_company=True)
```

### 2. The `SQL()` Builder
To prevent SQL injection and improve code maintainability, Odoo 18 introduces a dedicated `SQL()` builder. Raw string formatting for queries is deprecated.
```python
from odoo.tools import SQL
query = SQL("SELECT id FROM %s WHERE active = %s", SQL.identifier(self._table), True)
self.env.cr.execute(query)
```

### 3. Record Rule Context (`allowed_company_ids`)
The context variable `company_ids` used in record rules is replaced/complemented by `allowed_company_ids` to better reflect the user's active company selection.

### 4. Preparation for Odoo 19
Odoo 18 strongly encourages:
- **Python Type Hints**: Methods should include parameter and return type annotations.
- **Strict Company Checks**: Moving away from manual domain filtering in relational fields.

## Breaking Changes and Deprecations

| Feature | Change in v18 | Migration Action |
|---------|---------------|------------------|
| `attrs` (XML) | Completely removed (since v17) | Use direct `invisible`, `readonly`, `required`. |
| Raw SQL Strings | Deprecated in favor of `SQL()` | Rewrite queries using `odoo.tools.SQL`. |
| `company_ids` | Use `allowed_company_ids` | Update Record Rules XML files. |
| `osv.osv` | Legacy code removal | Ensure all models use `models.Model`. |

## Module Layout Changes
- **Manifest Assets**: The `web.assets_backend` bundle remains the primary place for JS/XML, but directory scanning (`**/*.js`) is now the standard pattern.
- **Icon Sizing**: Ensure `static/description/icon.png` is high-resolution for the new app drawer.

## Performance Improvements
- **Search Optimization**: Better use of B-tree indexes for `Char` fields.
- **Prefetching**: Enhanced ORM prefetching for relational fields in loops.
- **OWL 2.x**: Significant reduction in DOM updates for list views.

## Migration Checklist (17.0 -> 18.0)
- [ ] Update `__manifest__.py` version to `18.0.1.0.0`.
- [ ] Replace `company_ids` with `allowed_company_ids` in Record Rules.
- [ ] Implement `_check_company_auto = True` on all multi-company models.
- [ ] Convert any raw SQL execution to the `SQL()` builder pattern.
- [ ] Add type hints to public methods to prepare for v19.
- [ ] Verify that all XML views use the new attribute syntax (no `attrs`).

## AI Agent Instructions
When working on Odoo 18.0 projects:
1. **Prioritize** the use of `SQL()` for any database-level query.
2. **Automate** company checks using the new model-level attributes.
3. **Ensure** type safety by adding Python type hints to new code.
4. **Follow** OWL 2.x patterns for any frontend modifications.
5. **Refer** to `allowed_company_ids` when defining cross-company security logic.
