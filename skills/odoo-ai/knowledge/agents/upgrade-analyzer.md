---
title: Upgrade Analyzer Agent
domain: agents
version: 18.0
edition: both
source: native
status: active
---

# Upgrade Analyzer Agent

The Upgrade Analyzer Agent specializes in detecting breaking changes and technical debt when moving Odoo modules between versions (e.g., from v14 to v18).

## 1. API & ORM Deprecations
- **v14 to v15:** Removal of `_columns` and `_defaults` (legacy OpenERP patterns).
- **v16 to v17:** Refactoring of `onchange` behavior and further optimization of the ORM.
- **General:** Moving from `@api.multi` (deprecated in v13) to implicit recordset handling.

## 2. Field & Model Changes
- **Field Renames:** Identifying when core fields (like `name` or `state`) have been moved to mixins or renamed in base modules.
- **Many2one to Many2many:** Detecting architectural shifts where a single relation was upgraded to multiple relations.
- **Type Changes:** Transitioning from `Integer` to `Float` or `Selection` to `Many2one`.

## 3. View Syntax Evolutions
- **The v17 Pivot:** The most significant change is the removal of the `attrs` attribute.
  ```xml
  <!-- Old (v14-v16) -->
  <field name="partner_id" attrs="{'invisible': [('state', '=', 'draft')], 'readonly': [('is_locked', '=', True)]}"/>

  <!-- New (v17+) -->
  <field name="partner_id" invisible="state == 'draft'" readonly="is_locked"/>
  ```
- **Control Flow:** Adoption of `<t if="...">` and `<t foreach="...">` in QWeb with stricter JS-like expressions.

## 4. Security Model Changes
- **Restrictive by Default:** Odoo has become stricter with ACLs. Modules that "worked" without proper `ir.model.access.csv` in v12 will fail completely in v17+.
- **User Groups:** Shifts in how `base.group_user` and other system groups are structured.

## 5. Frontend & OWL Migration
- **Legacy Widgets:** Identification of deprecated `widget="..."` attributes in views.
- **JS Classes:** Mapping of `WebClient` extensions to the modern OWL component registry.
- **Asset Bundles:** Transition from XML-based asset declarations to the `assets` key in the `__manifest__.py`.

## 6. Upgrade Impact Report
The agent generates a report categorized by:
- **Blockers:** Breaking changes that will prevent the module from installing.
- **Warnings:** Deprecated patterns that still work but should be updated.
- **Optimizations:** New features in the target version that can replace custom code.
