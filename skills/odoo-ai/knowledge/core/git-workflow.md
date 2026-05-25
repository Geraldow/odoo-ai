---
title: Alesco Git Workflow
domain: core
version: 18.0
edition: both
source: odoo-contribute
status: complete
priority: P2
---

# Alesco Git Workflow

## Branch Model

| Branch | Purpose | Rule |
|---|---|---|
| `st_<project>` | Staging for one project | Normal development target |
| `st_produccion` | Shared staging before production | Allowed staging branch |
| `produccion` | Production | Requires explicit authorization |
| `db_<project>` | Database/production-like branch | Restricted |

## Commit Flow

1. Work on `st_<project>` or `st_produccion`.
2. Run branch safety before commit/push.
3. Commit using Conventional Commits.
4. Push only after explicit user authorization.
5. Validate staging.
6. Push/merge to production only after a second explicit authorization.

## Blocked Operations

Never run these unless project governance explicitly changes:
- `git push --force`
- `git push -f`
- `git push origin --delete`
- `git rebase`
- `git reset --soft`, `--mixed`, or `--hard`

## Commit Message

```text
type(scope): short description

- High-level change
- Verification performed
```

Use English keywords (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`) and
Spanish or English descriptions matching the user's prompt.
