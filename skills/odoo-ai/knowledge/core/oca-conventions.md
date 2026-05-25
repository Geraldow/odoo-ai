---
title: OCA Conventions
domain: core
version: 18.0
edition: both
source: odoo-contribute
status: complete
priority: P2
---

# OCA Conventions

## Module Structure

```text
my_module/
  __init__.py
  __manifest__.py
  models/
  views/
  security/
  data/
  tests/
```

## Naming

- Module names: lowercase with underscores.
- Models: dotted technical names, e.g. `sale.margin.rule`.
- XML IDs: `module_record_purpose`, stable and descriptive.
- Security IDs: `access_model_group`.
- Test files: `tests/test_<feature>.py`.

## Python Style

- Use `@api.model_create_multi` for `create()`.
- Use `for record in self` in computes and constraints.
- Use `_("%s") % value`, not f-strings inside `_()`.
- Prefer `Command.create/update/link` for x2many values when available.
- Avoid deprecated APIs for the target Odoo version.

## XML Style

- Odoo 18 uses direct boolean expressions, not legacy `attrs`.
- Keep inherited views narrow and stable.
- Verify every `ref=` XML ID exists.
- Keep security data loaded before views that rely on groups.

## Review Checklist

- [ ] Manifest has license, version, depends, data, installable.
- [ ] New models have ACLs.
- [ ] Views are version-compatible.
- [ ] Tests cover changed behavior when feasible.
- [ ] Changelog/version bump exists when needed.
