---
title: Version Comparison v14→v18
domain: core
version: all
edition: both
source: fhidalgo
status: active
---

# Version Comparison v14→v18

## Purpose
Comparison of technical changes, API evolution, and requirements from Odoo 14 to Odoo 18.

## Requirement Timeline

| Feature | v14 | v15 | v16 | v17 | v18 |
|---------|-----|-----|-----|-----|-----|
| **Python** | 3.6+ | 3.8+ | 3.10+ | 3.10+ | 3.11+ |
| **JS System** | odoo.define | ES Module | ES Module | ES Module | ES Module |
| **OWL Version** | N/A | OWL 1.x | OWL 2.x | OWL 2.x | OWL 2.x |
| **View Syntax** | `attrs` | `attrs` | `attrs` / Direct | Direct | Direct |

## ORM Evolution

| Component | Legacy Pattern | Modern Pattern (v17+) | Notes |
|-----------|----------------|-----------------------|-------|
| **Create** | `def create(self, vals)` | `@api.model_create_multi` | v17+ requires multi-create. |
| **x2many** | `(0, 0, {vals})` | `Command.create({vals})` | v16+ uses `Command` class. |
| **SQL** | `self.env.cr.execute("...")` | `self.env.cr.execute(SQL("..."))` | v18+ introduces `SQL()` builder. |
| **Company** | Manual domains | `_check_company_auto = True` | v18+ automated checks. |

## View Attribute Evolution

In Odoo 17 and 18, the `attrs` and `states` attributes were removed in favor of direct Python expressions.

| Legacy (v14-v16) | Modern (v17-v18) |
|------------------|------------------|
| `attrs="{'invisible': [('state', '=', 'draft')]}"` | `invisible="state == 'draft'"` |
| `attrs="{'readonly': [('state', '!=', 'draft')]}"` | `readonly="state != 'draft'"` |
| `states="draft,open"` (on buttons) | `invisible="state not in ('draft', 'open')"` |

## Security and Rules

| Feature | Legacy | Modern (v17/v18) |
|---------|--------|------------------|
| **Context** | `company_ids` | `allowed_company_ids` |
| **Checks** | Manual constraints | `check_company=True` (v18) |
| **Domain** | `[('company_id', 'in', company_ids)]` | `[('company_id', 'in', allowed_company_ids)]` |

## Migration Path Summary

### v14 → v16
- Transition from `track_visibility` to `tracking`.
- Adopt OWL 2 components for frontend.
- Start using the `Command` class for relational fields.

### v16 → v17
- **Major**: Remove all `attrs` and `states` from XML.
- Update `create()` methods to use `@api.model_create_multi`.
- Convert domains to Python expressions in XML.

### v17 → v18
- Adopt the `SQL()` builder for all raw database queries.
- Implement `_check_company_auto = True` for models with `company_id`.
- Update record rules to use `allowed_company_ids`.
- Start adding Python type hints to prepare for v19.

## AI Agent Instructions
1. **Detect** the Odoo version from `__manifest__.py`.
2. **Apply** the correct view syntax: Use direct attributes for v17/v18, `attrs` only for v16 and below.
3. **Use** `Command` for all versions v16+.
4. **Enforce** `_check_company_auto` and `SQL()` builder only for v18+.
5. **Always** check for `@api.model_create_multi` when extending or creating `create` methods.
