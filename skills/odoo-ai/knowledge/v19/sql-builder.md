---
title: Odoo 19 — SQL Builder
domain: orm
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — SQL Builder

## Purpose
New SQL expression builder and query API introduced in Odoo 19. String-based SQL queries are strictly prohibited and will fail. All SQL execution must wrap the query in the `SQL()` builder from `odoo.tools`.

## Mandatory Usage

The `SQL()` object safely handles parameter injection, avoiding SQL injection vulnerabilities dynamically.

### Basic Usage

```python
from odoo.tools import SQL
from odoo import models

class MyModel(models.Model):
    _name = 'my.model'

    def _get_statistics(self) -> dict:
        # Correct Odoo 19 Pattern
        self.env.cr.execute(SQL(
            """
            SELECT state, COUNT(*) as count
            FROM my_model
            WHERE company_id = %s
            GROUP BY state
            """,
            self.env.company.id
        ))
        return {row['state']: row['count'] for row in self.env.cr.dictfetchall()}
```

### Migration from String SQL

**Old v18 (Will Crash in v19):**
```python
self.env.cr.execute("""
    SELECT id FROM my_model WHERE state = %s
""", ('draft',))
```

**New v19 (Required):**
```python
from odoo.tools import SQL

self.env.cr.execute(SQL(
    "SELECT id FROM my_model WHERE state = %s",
    'draft'
))
```

Notice that parameters are passed dynamically as arguments to `SQL()`, not via a tuple in `execute()`.

### Bulk Updates
```python
def _bulk_update(self, ids: list[int], new_state: str) -> int:
    if not ids:
        return 0

    self.env.cr.execute(SQL(
        """
        UPDATE my_model
        SET state = %s
        WHERE id IN %s
        RETURNING id
        """,
        new_state,
        tuple(ids)
    ))
    return len(self.env.cr.fetchall())
```
