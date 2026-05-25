---
title: Odoo 18→19 Upgrade Guide
domain: migration
version: 19.0
edition: both
source: native
status: active
---

# Odoo 18→19 Upgrade Guide

## Purpose
Step-by-step upgrade path from Odoo 18 to 19 with known breaking changes.

## Upgrade Checklist

1. **Migrate all raw SQL queries:**
   Search for all instances of `self.env.cr.execute` and wrap the query strings and parameters in `odoo.tools.SQL()`.
2. **Refactor SQL Constraints:**
   Search for `_sql_constraints = [` and convert every tuple into a `_my_constraint_name = models.Constraint('SQL', 'Message')` attribute.
3. **Update user creation scripts:**
   Search for `res.users` creation logic. Ensure `groups_id` is removed from the `create` dictionary and added via a subsequent `write()` to the group or the user object.
4. **Upgrade OWL Components (2.x -> 3.x):**
   - Update `static props` to use object notation: `{ type: String, required: true }`.
   - Update lifecycle hooks like `onWillStart` to ensure correct Promise/async handling.
5. **Python 3.12 Compatibility:**
   Ensure no deprecated Python 3.10/3.11 libraries are used. Start using PEP 695 type parameter syntax if preferred.
6. **Apply Type Hints:**
   Go through public ORM methods (actions, computes, constraints) and add return types (`-> bool`, `-> dict`, etc.) and parameter types.
7. **Multi-company verification:**
   Ensure models with `company_id` declare `_check_company_auto = True` and relational fields have `check_company=True`.
