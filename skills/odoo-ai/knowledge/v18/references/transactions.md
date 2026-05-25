---
title: Odoo 18 — Transactions Reference
domain: orm
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Transactions Reference

Odoo uses PostgreSQL transactions to ensure ACID compliance. Understanding how to manage the database cursor and environment is critical for complex logic.

## Transaction Management

### Savepoints
Use `cr.savepoint()` to create an atomic block that can be rolled back without affecting the entire transaction.

```python
try:
    with self.env.cr.savepoint():
        # Do something that might fail
        record.write({'name': 'New Name'})
        if some_condition:
            raise UserError("Rollback this part only")
except UserError:
    # 'New Name' is NOT saved, but the rest of the transaction continues
    pass
```

### Manual Commit
**Warning:** Avoid `cr.commit()` in standard business logic. It breaks atomicity and can lead to data inconsistency if a later part of the request fails. It is mostly used in long-running scripts or cron jobs.

```python
self.env.cr.commit()
```

## Executing SQL Directly

While the ORM is preferred, sometimes direct SQL is necessary for performance.

```python
self.env.cr.execute("SELECT id FROM res_partner WHERE name = %s", (name,))
res = self.env.cr.fetchone()
# Or
res = self.env.cr.dictfetchall()
```
Always use placeholders (`%s`) to prevent SQL injection.

## Environment Context

### `with_env()`
Switch to a new environment with a different context or user.

```python
new_env = self.env(user=other_user_id)
record_in_new_env = record.with_env(new_env)
```

### `Environment.manage()`
Used when creating an environment outside of a standard request (e.g., in a new thread).

```python
with odoo.api.Environment.manage():
    with odoo.registry(db_name).cursor() as cr:
        env = odoo.api.Environment(cr, uid, {})
        # Do work
```

## Cursor Context Management

The cursor (`cr`) is part of the environment. In Odoo 18, it is automatically managed by the framework for web requests, but must be handled carefully in manual scripts.

```python
# The cursor is closed automatically when the 'with' block exits
with self.pool.cursor() as new_cr:
    new_env = self.env(cr=new_cr)
    # Perform operations in a separate transaction
```

## Transaction Isolation
Odoo typically runs in `READ COMMITTED` isolation level. Be aware of phantom reads in highly concurrent environments. Use `FOR UPDATE` in SQL or `flush()`/`invalidate_recordset()` in the ORM to manage cache consistency.
