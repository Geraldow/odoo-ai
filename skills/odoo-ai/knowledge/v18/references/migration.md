---
title: Odoo 18 — Migration Reference
domain: migration
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Migration Reference

Migration scripts are used to transform data when upgrading between Odoo versions or refactoring a module.

## Script Structure

Migration scripts are placed in the `migrations/` directory of a module.
Structure: `migrations/<version>/[pre|post]-migrate.py`

### File Naming
- `pre-migrate.py`: Runs BEFORE the module is updated. Use for renaming columns/tables.
- `post-migrate.py`: Runs AFTER the module is updated. Use for data transformation that requires the new schema.

## Function Signature

Both pre and post scripts must define a `migrate` function.

```python
def migrate(cr, version):
    """
    cr: Database cursor
    version: The version of the module currently installed (before upgrade)
    """
    # Logic goes here
    pass
```

## OpenUpgrade Helpers

The Odoo Community Association (OCA) provides `openupgradelib`, a set of utilities to simplify common migration tasks.

| Helper | Purpose |
|--------|---------|
| `rename_models(cr, list_of_tuples)` | Renames models and their associated tables/fields. |
| `rename_columns(cr, list_of_tuples)` | Renames columns within a table. |
| `rename_tables(cr, list_of_tuples)` | Renames database tables. |
| `merge_models(cr, source, target)` | Merges data from one model into another. |

Example using `openupgradelib`:
```python
from openupgradelib import openupgrade

def migrate(cr, version):
    if not version:
        return
    openupgrade.rename_columns(cr, {
        'my_model': [('old_field', 'new_field')],
    })
```

## Best Practices

1. **Idempotency**: Scripts should be safe to run multiple times. Check if a column exists before trying to rename it.
2. **Direct SQL**: Use `cr.execute()` for heavy data transformations to bypass ORM overhead and constraints that might not be met during migration.
3. **Avoid ORM**: In `pre-migrate`, the ORM might be in an inconsistent state. Stick to SQL. In `post-migrate`, you can use `env`, but be cautious.
4. **Logging**: Use `logging.getLogger(__name__)` to track progress.

## Version Format
Odoo versions are usually compared using `odoo.tools.parse_version`. Migration scripts are triggered based on the version number in the `__manifest__.py`.
