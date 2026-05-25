---
title: Security Scanner Guide
domain: security
version: 18.0
edition: both
source: native
status: complete
priority: P4
---

# Security Scanner Guide

## Purpose

Use scanners to catch defensive coding mistakes before review. Scanner output is
a starting point; the developer must still understand and fix the underlying
pattern.

## Recommended Tools

- `pylint-odoo`: Odoo-specific Python and manifest checks.
- OCA pre-commit hooks: formatting, linting, XML, manifest, and common mistakes.
- GitHub Actions: repeatable CI gate for PRs.

## CI Pattern

```yaml
- name: Install lint tools
  run: pip install pre-commit pylint-odoo

- name: Run pre-commit
  run: pre-commit run --all-files
```

## What To Correct

Always correct:
- SQL built from concatenated/interpolated values.
- Missing ACLs for new models.
- Unsafe QWeb rendering of user data.
- Broad `sudo()` without a business reason.
- Routes missing explicit `auth`.

May be ignored only with a comment and reviewer agreement:
- False positive in generated code.
- Legacy module warning outside the changed area.
- Rule that conflicts with a documented Odoo version-specific pattern.

## Review Workflow

1. Run scanner locally.
2. Fix high-confidence findings first.
3. Re-run scanner.
4. Document any intentional exception in the PR.
5. Verify access-sensitive behavior with a non-admin user.
