---
title: Odoo 19 — Performance Reference
domain: performance
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Performance Reference

Odoo 19 emphasizes efficient data handling through advanced ORM features, optimized database interactions, and aggressive caching strategies.

## ORM Performance Patterns

### Prefetching Optimization
Odoo automatically fetches fields for all records in a recordset when any single record's field is accessed.

- **Batch Access**: Avoid accessing fields in a loop over individual browse results.
- **`with_prefetch()`**: Manually define the set of records that should be prefetched together to avoid "N+1" query problems.

### Efficient Aggregations
Always delegate mathematical aggregations to the database using `_read_group`.

```python
# HIGH PERFORMANCE (SQL Aggregation)
groups = self.env['account.move.line']._read_group(
    [('parent_state', '=', 'posted')],
    ['partner_id'],
    ['balance:sum']
)

# POOR PERFORMANCE (Python Aggregation)
lines = self.env['account.move.line'].search([('parent_state', '=', 'posted')])
total = sum(lines.mapped('balance'))
```

### Batch Operations
Minimize roundtrips by processing records in bulk.

- **`create([vals_list])`**: Passing a list of dictionaries is significantly faster than calling create in a loop.
- **`write(vals)`**: Calling write on a recordset of 1000 records executes a single SQL update.

## Database Tuning

### Strategic Indexing
- **`index=True`**: Use on fields frequently used in domains (e.g., `state`, `date`, `partner_id`).
- **Composite Indexes**: Defined via `_sql_constraints` for complex multi-column lookups.
- **GIN/GiST Indexes**: Essential for high-performance searching within `JSONB` fields or full-text search.

### Domain Filtering
- Order domain leaves from most restrictive to least restrictive.
- Be cautious with `child_of` operators on deep hierarchies; they can expand into massive SQL `IN` clauses.

## Caching and Memory Management

- **ORM Cache**: Odoo stores record data in memory. Use `invalidate_model()` or `invalidate_recordset()` if you modify data via direct SQL.
- **`flush()`**: Forces the ORM to write pending changes to the database. Required before executing direct SQL that relies on recent ORM updates.

## Profiling and Diagnostics

Odoo 19 provides built-in tools to identify bottlenecks:
- **UI Profiler**: Accessible via the debug icon -> "Toggle Profiler".
- **Code Profiler**:
```python
from odoo.tools.profiler import Profile

with Profile(description="Batch Processing"):
    # Logic to analyze
    self._process_data()
```
- **Logging SQL**: Set the log level for `odoo.sql_db` to `DEBUG` to see all queries in the server logs.
