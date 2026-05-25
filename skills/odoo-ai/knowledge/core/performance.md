---
title: Performance Guide
domain: core
version: all
edition: both
source: fhidalgo
status: active
---

# Performance Guide

## Purpose
N+1 detection, batch processing, SQL optimization, and memory management for Odoo.

## Core Performance Principles
1. **Minimize DB Queries**: Avoid N+1 patterns. Use prefetching and batch operations.
2. **Indexing**: Index fields used in domains, order by, and record rules.
3. **Stored Computes**: Use `store=True` for computed fields that are frequently read but infrequently changed.
4. **ORM vs SQL**: Use ORM for business logic and SQL for high-volume data manipulations.

## Solving the N+1 Query Problem
N+1 occurs when you loop over a recordset and access a relational field, triggering a query for each record.

```python
# BAD: N+1 queries
for order in orders:
    print(order.partner_id.name)  # Query for every iteration

# GOOD: Prefetching (Odoo does this automatically for search results)
# Accessing one record's field triggers a batch read for all in the recordset.
orders.mapped('partner_id.name')  # Explicitly trigger prefetch

# BETTER: search_read
# Directly fetch specific fields for a set of records in one query.
data = self.env['sale.order'].search_read([('state', '=', 'sale')], ['name', 'amount_total'])
```

## Batch Processing
Always process records in batches to minimize overhead and database roundtrips.

```python
# Create
self.env['my.model'].create([vals1, vals2, vals3])  # Multi-create

# Write
recordset.write({'state': 'done'})  # Updates all at once

# read_group (Aggregations)
# Use instead of looping and searching to count/sum records.
stats = self.env['sale.order'].read_group(
    [('state', '=', 'sale')], ['partner_id', 'amount_total'], ['partner_id']
)
```

## Database Indexing
Index fields that are frequently used in:
- `search()` domains.
- `ir.rule` (Record Rules).
- `_order` attribute.
- `Many2one` relations.

```python
name = fields.Char(index=True)  # Standard index
code = fields.Char(index='btree_not_null')  # v16+ Specialized
search_tag = fields.Char(index='trigram')  # v16+ For ILIKE searches
```

## SQL Builder Optimization (v18+)
Use the `SQL()` builder for bulk operations or complex queries where the ORM is too slow.

```python
from odoo.tools import SQL

def _bulk_close_orders(self, company_id):
    query = SQL(
        "UPDATE sale_order SET state = 'done' WHERE company_id = %s AND state = 'draft'",
        company_id
    )
    self.env.cr.execute(query)
    self.invalidate_model()  # Important: clear ORM cache after raw SQL
```

## Memory Management for Large Datasets
When processing millions of records, use batches and clear the cache.

```python
def process_millions(self):
    batch_size = 5000
    while True:
        records = self.search([('processed', '=', False)], limit=batch_size)
        if not records:
            break
        records._do_work()
        records.write({'processed': True})
        self.env.cr.commit()  # Optional: commit batch
        self.env.invalidate_all()  # Clear memory
```

## Performance Checklist
- [ ] Use `@api.model_create_multi` for all `create` methods.
- [ ] Use `search_count()` instead of `len(search())`.
- [ ] Avoid `sudo()` inside loops; it creates a new environment and breaks prefetching.
- [ ] Use `mapped()` and `filtered()` for in-memory operations on loaded recordsets.
- [ ] Profile slow methods using `from odoo.tools.profiler import profile`.
- [ ] For heavy computations, use `read_group` instead of manual Python loops.
