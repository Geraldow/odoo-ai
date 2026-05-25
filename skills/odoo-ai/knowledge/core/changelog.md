---
title: Changelog Rules
domain: core
version: 18.0
edition: both
source: odoo-contribute
status: complete
priority: P2
---

# Changelog Rules

## Format

Follow Keep a Changelog with Alesco section labels:

```markdown
## [18.0.1.1.0] - 2026-05-23

### Added

- New user-visible capability [(#12)](https://github.com/org/repo/pull/12)

### Changed
### Removed
### Fixed
### Security
```

## Version Bumps

| Change | Bump |
|---|---|
| Bug fix or documentation-only release | Patch |
| New field, view, button, or user-visible feature | Minor |
| Breaking behavior or removal | Major |
| Security fix | Patch or minor, depending on behavior impact |

Odoo module versions use `{odoo_major}.{major}.{minor}.{patch}`.

## Rules

- Add entries to the unreleased/current target section.
- Do not modify already released sections.
- Link PRs when known.
- Bump `__manifest__.py` when DB schema, views, security, or behavior changed.
- Use `Security` for access rule fixes, exposed route corrections, or sensitive data handling.
