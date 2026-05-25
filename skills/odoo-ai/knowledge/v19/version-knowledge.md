---
title: Odoo 19 — Version Knowledge
domain: reference
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Version Knowledge

## Purpose
Comprehensive version-specific knowledge base for Odoo 19 (traps, gotchas, undocumented behaviors).

## Python 3.12 Typing Capabilities
Odoo 19 fully embraces Python 3.12. You should utilize:
- **`typing.Self`**: For methods that return the same recordset type.
- **Pattern Matching (`match` statements)**: Excellent for processing state fields cleanly instead of long `if/elif` chains.

```python
from typing import Self

def process_state(self) -> str:
    match self.state:
        case 'draft':
            return 'Draft processing'
        case 'done' | 'cancel':
            return 'Finalized'
        case _:
            return 'Unknown'
```

## Security: res.users
Never pass `groups_id` in a `create()` vals dictionary for `res.users`. This will silently fail or throw a security warning in v19. Group assignment must happen post-creation.

## SQL Builder Gotchas
When using the `SQL()` builder with `IN` clauses, the parameter passed must be a python `tuple`. Passing a `list` might cause psycopg2 binding errors depending on the context.
```python
from odoo.tools import SQL

# Ensure ids is a tuple
self.env.cr.execute(SQL("SELECT id FROM table WHERE id IN %s", tuple(my_list)))
```

## View and UI Changes
With OWL 3.x taking the helm, raw Javascript component initialization has strict validation on startup. If a required prop is missing from a parent XML view or JS template, the component will fatal error instantly instead of silently passing `undefined`. Ensure `static props` accurately reflect optionality.
