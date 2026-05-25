---
title: Operations Commands
domain: devops
version: 18.0
edition: both
source: odoo-contribute
status: complete
priority: P4
---

# Odoo Operations Commands

## Purpose

Use these commands for safe diagnostics. Avoid collecting or saving customer PII
in Engram, logs, screenshots, or reports.

## Logs

```bash
docker compose logs web --tail=120
docker compose logs db --tail=80
```

For Odoo.sh or remote servers, prefer scoped log excerpts around the error time.
Do not paste full logs containing personal data.

## Database Inspection

```bash
docker compose exec -T db psql -U odoo -d <db_name> -c "SELECT name, state FROM ir_module_module WHERE name = '<module>';"
```

Use read-only SQL for diagnostics. Any write SQL must be reviewed, reversible,
and backed up.

## Module Update

```bash
docker compose exec -T web odoo -d <db_name> -u <module> --stop-after-init
```

Before updating:
- Confirm database name.
- Confirm target module.
- Ensure the branch contains the intended code.
- Prefer staging before production.

## Backups

Before destructive operations:
- Create a database backup.
- Record branch, commit, database, and timestamp.
- Confirm restore path is known.

## Sensitive Data Rule

Never save RUC, DNI, payroll, customer emails, invoices, tokens, or transaction
details into Engram. Summarize operational findings without personal data.
