---
title: Data Migration Patterns
domain: core
version: all
edition: both
source: existing
status: active
---

# Data Migration Patterns

Managing data transitions in Odoo requires precision to avoid data loss or XML ID corruption. These patterns follow OpenUpgrade and Odoo core best practices.

## 1. Hooks: Pre, Post, and Uninstall
- **`pre_init_hook`**: Run before the module is installed. Used for SQL-level schema preparation.
- **`post_init_hook`**: Run after installation. Ideal for populating new fields using the ORM.
- **`uninstall_hook`**: Cleanup logic when removing a module.

```python
# __init__.py
def post_init_hook(cr, registry):
    from odoo import api, SUPERUSER_ID
    env = api.Environment(cr, SUPERUSER_ID, {})
    # Logic to populate data
```

## 2. Migration Scripts (`migrations/`)
Odoo automatically looks for scripts in `migrations/VERSION/{pre,post}-migrate.py`.
- **`pre-migrate.py`**: Use for `RENAME COLUMN` or moving data to temporary tables. Uses raw SQL.
- **`post-migrate.py`**: Use for complex logic that requires the new module structure to be loaded.

## 3. Safe Column Rename
Avoid deleting and recreating columns, which loses data.
```python
# migrations/17.0.1.1/pre-migrate.py
def migrate(cr, v):
    if not v:
        return
    # Check if old column exists before renaming
    cr.execute("ALTER TABLE sale_order RENAME COLUMN old_field TO new_field")
```

## 4. XML ID Mapping (`ir.model.data`)
When moving data from one module to another, you must update the `module` name in `ir_model_data` to prevent duplicate records or broken references.
```sql
UPDATE ir_model_data 
SET module = 'new_module' 
WHERE module = 'old_module' AND name = 'record_xml_id';
```

## 5. CSV Import & Large Datasets
For millions of records, avoid `env['model'].create()`.
- **Use `copy_from`**: PostgreSQL command for fast bulk inserts.
- **Batched ORM:** If using ORM, use `flush()` and `invalidate_cache()` every 1000 records to manage memory.

## 6. Record Rule & ACL Migration
When security models change, ensure that new groups are mapped to existing users in `post-migrate.py` to prevent "Access Denied" errors immediately after upgrade.
