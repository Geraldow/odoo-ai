---
name: odoo-overview
description: >
  Gives AI agents a high-level understanding of the Odoo ecosystem: stack
  components, version matrix, Python compatibility, and module discovery.
  Trigger: When answering general Odoo architecture questions, determining
  which skill to load, or understanding version differences.
license: MIT
metadata:
  author: Geraldow
  version: "1.0.0"
  scope: [root, core]
  supported_versions: ["17", "18"]
  auto_invoke:
    - "General Odoo architecture questions"
    - "Understanding the Odoo stack or components"
    - "Determining which Odoo version is in use"
    - "Choosing which skill to load for a task"
---

## When to Use

Load this skill when:

- You need a high-level understanding of Odoo before diving into specifics
- You're unsure which domain-specific skill to load for a task
- A developer asks about the Odoo stack, architecture, or version differences
- You need to detect the Odoo version from a project
- You want a quick reference of what changed between versions

This skill is the **entry point**. It tells you WHAT Odoo is and WHERE to go next.
For HOW to do specific things, load the domain-specific skills listed in the Component Map.

---

## The Odoo Stack

Odoo is a full-stack business application framework:

```text
┌─────────────────────────────────────────────┐
│              Browser / Client                │
│  ┌────────────────────────────────────────┐  │
│  │  OWL 2 Components (JS/XML)            │  │
│  │  QWeb Templates (t-tags)              │  │
│  │  SCSS / CSS Assets                    │  │
│  └────────────────────────────────────────┘  │
├─────────────────────────────────────────────┤
│              Web Server (Werkzeug)           │
│  ┌────────────────────────────────────────┐  │
│  │  HTTP Controllers (routes)            │  │
│  │  JSON-RPC / XML-RPC endpoints         │  │
│  └────────────────────────────────────────┘  │
├─────────────────────────────────────────────┤
│              Business Logic (Python)         │
│  ┌────────────────────────────────────────┐  │
│  │  Models (ORM layer)                   │  │
│  │  Fields, Computed, Constraints        │  │
│  │  Security (ir.model.access, ir.rule)  │  │
│  │  Wizards (TransientModel)             │  │
│  │  Cron jobs (ir.cron)                  │  │
│  └────────────────────────────────────────┘  │
├─────────────────────────────────────────────┤
│              Database (PostgreSQL)           │
│  ┌────────────────────────────────────────┐  │
│  │  One table per model                  │  │
│  │  ir_model_data (XML IDs)              │  │
│  │  ir_model_access (security)           │  │
│  └────────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Key Facts

- **Language**: Python 3.10+ (v17/v18)
- **Database**: PostgreSQL only (no MySQL, no SQLite)
- **ORM**: Custom ORM — NOT SQLAlchemy, NOT Django ORM
- **Frontend**: OWL 2 (v17+) — Odoo's own reactive component framework
- **Views**: Defined in XML, rendered server-side + client-side
- **Configuration**: `odoo.conf` or CLI parameters
- **Module system**: Addons discovered via `addons_path` in config

---

## Version Matrix

| Feature | v17 | v18 |
|---------|-----|-----|
| **Python** | 3.10+ | 3.10+ |
| **OWL** | OWL 2 | OWL 2 |
| `name_get()` | Deprecated | Removed |
| `attrs="{}"` in XML | **REMOVED** | **REMOVED** |
| `type="json"` controller | `"jsonrpc"` | `"jsonrpc"` |
| `mail.channel` | `discuss.channel` | `discuss.channel` |
| `Command` objects | Supported | Required |
| `ir_property` | Table | JSONB column |
| `groups_id` (res.users) | Active | `group_ids` |

For detailed version differences with code examples, see:
- [version-matrix.md](assets/version-matrix.md) — Full matrix with migration examples

---

## Critical Version Traps

These are the **top 5 mistakes** AI agents make when generating Odoo code:

### 1. Using `attrs` in XML views (v17+)

```xml
<!-- WRONG — crashes on v17+ -->
<field name="amount" attrs="{'invisible': [('state', '!=', 'draft')]}"/>

<!-- CORRECT — inline Python expression -->
<field name="amount" invisible="state != 'draft'"/>
```

### 2. Using `name_get()` (v17+)

```python
# WRONG — deprecated in v17, removed in v18
def name_get(self):
    return [(r.id, f"[{r.code}] {r.name}") for r in self]

# CORRECT — computed display_name
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

### 3. Using `type="json"` in controllers (v17+)

```python
# WRONG — renamed in v17
@http.route('/api/data', type='json', auth='user')

# CORRECT
@http.route('/api/data', type='jsonrpc', auth='user')
```

### 4. Using tuples for x2many writes (v17+)

```python
# WRONG — deprecated tuple syntax
record.write({'tag_ids': [(4, tag_id)]})

# CORRECT — Command objects
from odoo.fields import Command
record.write({'tag_ids': [Command.link(tag_id)]})
```

### 5. Missing security rules

```text
Every new model MUST have:
1. An entry in security/ir.model.access.csv
2. Record rules (ir.rule) if data is multi-company or sensitive

Without ir.model.access.csv → AccessError on ANY operation.
```

---

## Component Map

Use this table to know which skill to load for each task:

| Component | What it covers | Skill |
|-----------|---------------|-------|
| Models, fields, ORM | Python models, field types, CRUD, recordsets | `odoo-development` |
| XML views | Form, tree, kanban, search, inheritance | `odoo-development` |
| Security | ir.model.access.csv, ir.rule, groups | `odoo-development` |
| Testing | TransactionCase, HttpCase, tours | `odoo-development` |
| Module structure | __manifest__.py, __init__.py, folder layout | `odoo-module` |
| OCA conventions | Naming, versioning, folder structure, style | `odoo-oca` |
| Controllers | HTTP routes, JSON-RPC, auth | `odoo-development` |
| OWL components | Frontend JS components, hooks | `odoo-development` |
| QWeb / Reports | Templates, PDF reports, t-tags | `odoo-development` |
| Wizards | TransientModel, wizard views | `odoo-development` |
| Chatter / Mail | mail.thread, activities, messaging | `odoo-development` |
| Scheduled actions / Cron | ir.cron, server actions, automated actions | `odoo-development` |
| Performance | N+1 avoidance, prefetch, read_group | `odoo-development` |
| Migration / Upgrade | Version upgrades, migration scripts | `odoo-development` |
| Data files | data/, demo/, XML/CSV records | `odoo-development` |
| Enterprise source / xpaths | Module maps, campos, xpaths Enterprise/Community | `odoo-source` |
| Git workflow | Commit, PR, changelog, CI pipeline | `odoo-contribute` |
| SSH / DB operations | Conexiones SSH, queries seguros, admin instancia | `odoo-ops` |

---

## Module Discovery

How Odoo finds and loads modules:

```text
1. odoo.conf defines addons_path:
   addons_path = /opt/odoo/addons,/opt/odoo/custom-addons

2. Odoo scans each directory for folders containing __manifest__.py

3. The `base` module loads FIRST (always) — it defines:
   - res.partner, res.users, res.company
   - ir.model, ir.model.fields, ir.model.access
   - ir.ui.view, ir.actions.*

4. Other modules load based on their `depends` list in __manifest__.py

5. Within each module, load order is:
   a. security/*.csv     — access rules (FIRST, so models can be used)
   b. data/*.xml         — static data
   c. views/*.xml        — UI definitions
   d. demo/*.xml         — only if --demo flag is set
```

### Version Detection

To determine the Odoo version of a project:

```python
# Read __manifest__.py → extract version field
# Example: 'version': '18.0.1.0.0'
#           ^^
#           First segment = Odoo version (18)
```

If no `__manifest__.py` is found, default to Odoo 18 (latest stable).

---

## Assets

- [version-matrix.md](assets/version-matrix.md) — Full version comparison with migration code examples

## References

- [odoo-architecture.md](references/odoo-architecture.md) — Official docs links, source code structure, development modes
