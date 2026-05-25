---
title: Odoo 19 — Transactions Reference
domain: orm
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Transactions Reference

Odoo 19 relies on PostgreSQL transactions to maintain ACID compliance. Proper transaction management ensures data integrity and prevents partial updates during failures.

## Transaction Control

### Savepoints
Savepoints allow for "sub-transactions" that can be rolled back independently of the main transaction.

```python
try:
    with self.env.cr.savepoint():
        # Atomic operations
        record.write({'status': 'processing'})
        if some_validation_fails:
            raise UserError("Validation failed")
except UserError:
    # Only the changes inside the 'with' block are rolled back
    pass
```

### Manual Commits
**Caution:** `cr.commit()` should rarely be used in standard business logic. It forces a commit to the database, making a rollback impossible if subsequent code fails. Use it primarily in long-running crons or scripts where data must be persisted incrementally.

```python
self.env.cr.commit()
```

## Direct SQL Execution

While the ORM is preferred, `cr.execute()` is used for performance-critical tasks or complex queries not supported by the ORM.

```python
self.env.cr.execute("""
    SELECT id, name 
    FROM res_partner 
    WHERE country_id = %s
""", (country_id,))
# Fetching results
results = self.env.cr.dictfetchall()
```
**Security Note:** Always use parameter binding (`%s`) to prevent SQL injection.

## Environment Management

### `with_env()`
Creates a new instance of a recordset attached to a different environment (e.g., a different user).

```python
# Run logic as the Superuser (ID 1)
sudo_env = self.env(user=1)
sudo_record = record.with_env(sudo_env)
```

### `Environment.manage()`
Essential when working with environments in multi-threaded contexts or outside the standard web request lifecycle.

```python
import odoo

with odoo.api.Environment.manage():
    with odoo.registry(db_name).cursor() as cr:
        env = odoo.api.Environment(cr, uid, {})
        # Perform operations
```

## Cursor Context

The database cursor (`cr`) is a resource that must be handled carefully. In standard Odoo requests, the framework manages the cursor. In manual scripts, use context managers to ensure the cursor is closed.

```python
with self.pool.cursor() as new_cr:
    new_env = self.env(cr=new_cr)
    # Operations in a separate database transaction
```

## Concurrency and Isolation
Odoo 19 operates under the `READ COMMITTED` isolation level. 
- Use `FOR UPDATE` in SQL to lock rows.
- Use `flush()` to ensure the ORM cache is written to the DB before direct SQL queries.
- Use `invalidate_recordset()` to clear the cache if data is modified via direct SQL.
