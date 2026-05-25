---
title: Security Audit Checklist
domain: security
version: 18.0
edition: both
source: native
status: complete
priority: P2
---

# Pre-Deploy Security Audit Checklist

Run this checklist before merging or deploying an Odoo custom module.

## Access Control

- [ ] Every new persistent model has an `ir.model.access.csv` entry.
- [ ] ACLs start with least privilege and grant write/create/unlink explicitly.
- [ ] Multi-company models have an `ir.rule` when records are company-bound.
- [ ] Owner/team-specific records have a record rule or explicit access check.
- [ ] Sensitive fields use `groups=`.

## ORM and SQL

- [ ] No `cr.execute()` uses string concatenation, `.format()`, or f-strings with values.
- [ ] Every SQL statement with values uses parameter binding.
- [ ] `sudo()` calls have minimal scope and an inline reason when non-obvious.
- [ ] Request values are whitelisted before `create()` or `write()`.

## Controllers and Portal

- [ ] Every `@http.route` declares `auth` explicitly.
- [ ] State-changing forms keep CSRF enabled unless a documented integration requires otherwise.
- [ ] Any ID received from the browser is checked for ownership or token access.
- [ ] Portal responses do not expose fields outside the user's allowed records.

## XML, QWeb, and Views

- [ ] No `t-raw` renders user-controlled data.
- [ ] User-facing values use `t-out`.
- [ ] Views do not expose sensitive fields to broad groups.
- [ ] XML data files do not create admin-only configuration visible to all users.

## Release Gate

- [ ] Security scanner/pre-commit checks pass or each warning is documented.
- [ ] Review was performed with a non-admin user when access rules changed.
- [ ] `__manifest__.py` version is bumped if security/data/view behavior changed.
