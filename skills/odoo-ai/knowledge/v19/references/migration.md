---
title: Odoo 19 — Migration Reference
domain: migration
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Migration Reference

Migration scripts in Odoo 19 handle data transformations required when upgrading versions or refactoring modules with schema changes.

## Migration Script Structure

Scripts are located in the `migrations/` directory of your module.
Path: `migrations/<version>/[pre|post]-migrate.py`

### Phases
- **pre-migrate.py**: Executed BEFORE the module update. Used for structural changes like renaming columns or tables to avoid data loss during the Odoo auto-update.
- **post-migrate.py**: Executed AFTER the module update. Used for complex data migrations that require the new schema or ORM logic to be in place.

## The `migrate` Function

Every migration script must implement a `migrate` function.

```python
def migrate(cr, version):
    """
    cr: The database cursor.
    version: The version string of the module currently installed.
    """
    if not version:
        return
    # Migration logic
```

## OpenUpgrade Helpers (OCA)

The OCA `openupgradelib` is the industry standard for simplifying migration tasks.

| Helper | Description |
|--------|-------------|
| `rename_models` | Updates model names in the DB and associated references. |
| `rename_columns` | Safely renames columns in a specific table. |
| `rename_tables` | Renames the underlying PostgreSQL table. |
| `merge_models` | Moves data from a source model to a target model. |

```python
from openupgradelib import openupgrade

def migrate(cr, version):
    if openupgrade.version_info(version) < [19, 0]:
        openupgrade.rename_columns(cr, {
            'res_partner': [('old_field', 'new_field')],
        })
```

## Migration Best Practices

1. **Idempotency**: Ensure scripts can run multiple times without error (e.g., check for column existence before renaming).
2. **Direct SQL in Pre-Migrate**: The ORM state is unreliable during the `pre` phase. Use `cr.execute()` for all structural changes.
3. **ORM in Post-Migrate**: You can use the ORM in `post-migrate` via `self.env`, but be aware that some constraints or triggers might cause side effects.
4. **Logging**: Use standard Python logging to provide visibility into the migration progress.
5. **Version Targeting**: Use `odoo.tools.parse_version` to handle logic targeting specific version ranges.

## Handling Module Renames
If a module is renamed, use `ir.model.data` updates in a pre-migration script to re-map XML IDs to the new module name.
