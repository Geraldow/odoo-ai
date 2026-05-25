---
title: Odoo 18 — Performance Reference
domain: performance
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Performance Reference

Optimizing Odoo involves efficient ORM usage, proper database indexing, and leveraging caching.

## ORM Optimization

### Prefetching
Odoo's ORM automatically prefetches fields for records in the same "prefetch set" (usually records from the same search result).

- Avoid iterating and calling `read()` or accessing fields on individual records if they are not part of the same recordset.
- Use `with_prefetch()` to manually group records for prefetching.

### `read_group` vs `search`
To perform aggregations (SUM, AVG, COUNT), always use `read_group()` or the newer `_read_group()` instead of searching and looping in Python.

```python
# Fast (SQL aggregation)
res = self.env['sale.order'].read_group(
    [('state', '=', 'sale')], ['amount_total:sum'], ['partner_id']
)

# Slow (Python aggregation)
orders = self.env['sale.order'].search([('state', '=', 'sale')])
total = sum(orders.mapped('amount_total'))
```

### Batch Operations
Use batch methods to minimize database roundtrips.

- **Create**: Pass a list of dictionaries to `create()`.
- **Write**: Updating multiple records with the same values is fast: `records.write({'state': 'done'})`.

## Database Optimization

### SQL Indexes
- **Automatic**: `index=True` on a field definition.
- **Manual**: Use `_sql_constraints` for unique indexes or custom SQL in `_auto_init`.
- **B-Tree**: Default. Good for equality and range queries.
- **GIN/GiST**: Use for JSONB or full-text search.

### Domain Optimization
- Put the most restrictive criteria first in domains.
- Avoid `child_of` or `parent_of` on large hierarchies if not indexed.
- Use `indexed` fields for searching.

## Caching and Invalidation

Odoo maintains an in-memory cache for records.

- `env.cache.invalidate()`: Clears the ORM cache. Use sparingly after direct SQL updates.
- `env.flush_all()`: Pushes all pending ORM changes to the database. Essential before running direct SQL queries that depend on recent ORM writes.

## Profiling

Use the built-in profiler to identify bottlenecks.
```python
from odoo.tools.profiler import Profile

with Profile(description="My Logic"):
    # Code to profile
    self.do_something()
```
The results can be viewed in the "Performance" section of the developer tools.
