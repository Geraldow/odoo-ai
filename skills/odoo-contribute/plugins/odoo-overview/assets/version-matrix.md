# Odoo Version Matrix — Detailed Reference

## Python Compatibility

| Odoo Version | Python Min | Python Max | Recommended |
|-------------|-----------|-----------|-------------|
| 16.0 | 3.7 | 3.10 | 3.10 |
| 17.0 | 3.10 | 3.12 | 3.10 |
| 18.0 | 3.10 | 3.12 | 3.12 |

---

## Breaking Changes: v16 → v17 → v18

### v16 → v17 (breaking — affects all v16 modules being ported)

#### `attrs` attribute REMOVED from XML views

```xml
<!-- ❌ WRONG — worked in v16, crashes on v17+ -->
<field name="amount" attrs="{'invisible': [('state', '!=', 'draft')]}"/>

<!-- ✅ CORRECT (v17+) — inline Python expressions -->
<field name="amount" invisible="state != 'draft'"/>
```

#### `states` attribute REMOVED from buttons/fields

```xml
<!-- ❌ WRONG — worked in v16, removed in v17 -->
<button name="action_confirm" states="draft,sent" string="Confirm" type="object"/>

<!-- ✅ CORRECT (v17+) -->
<button name="action_confirm" string="Confirm" type="object"
        invisible="state not in ('draft', 'sent')"/>
```

#### `@colors` / `@fonts` REMOVED from list/tree views

```xml
<!-- ❌ WRONG — worked in v16 -->
<tree colors="red:state=='cancel';green:state=='done'">

<!-- ✅ CORRECT (v17+) -->
<list decoration-danger="state == 'cancel'" decoration-success="state == 'done'">
```

#### `name_get()` deprecated (v17) / removed (v18)

```python
# ❌ WRONG — worked in v16, deprecated v17, removed v18
def name_get(self):
    return [(r.id, f"[{r.code}] {r.name}") for r in self]

# ✅ CORRECT (v17+)
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

#### `type="json"` renamed in controllers

```python
# ❌ WRONG — worked in v16, renamed in v17
@http.route('/api/data', type='json', auth='user')

# ✅ CORRECT (v17+)
@http.route('/api/data', type='jsonrpc', auth='user')
```

#### `mail.channel` renamed to `discuss.channel`

```python
# ❌ WRONG — worked in v16
channel = self.env['mail.channel'].create({...})

# ✅ CORRECT (v17+)
channel = self.env['discuss.channel'].create({...})
```

#### Tuple syntax for x2many — use `Command` API

```python
# ❌ WRONG — v16 tuple syntax
record.write({'line_ids': [(0, 0, {'name': 'New'})]})

# ✅ CORRECT (v17+)
from odoo.fields import Command
record.write({'line_ids': [Command.create({'name': 'New'})]})
```

#### Assets declaration changed (manifest)

```python
# ❌ WRONG — v16 `qweb` key removed in v17
'qweb': ['static/src/xml/my_template.xml'],

# ✅ CORRECT (v17+) — ir.asset records in data XML
```

---

### v17 → v18 specific changes

#### `ir_property` table removed — JSONB columns

```python
# v17 — company-dependent fields stored in ir_property table
# v18 — stored directly as JSONB columns on the model table
# Impact: direct SQL queries on ir_property will break
```

#### `groups_id` renamed to `group_ids` on res.users

```python
# v17
user.groups_id = [(4, group_id)]

# v18
user.group_ids = [Command.link(group_id)]
```

#### `search_fetch()` method added

```python
# v17 — 2 queries
records = self.search(domain)
data = records.read(['name', 'state'])

# v18 — single optimized query
records = self.search_fetch(domain, ['name', 'state'])
```

---

## Feature Availability Matrix

| Feature | v16 | v17 | v18 |
|---------|:---:|:---:|:---:|
| `attrs` in XML | ✅ | ❌ | ❌ |
| Inline view expressions | ❌ | ✅ | ✅ |
| `states` on buttons/fields | ✅ | ❌ | ❌ |
| `@colors`/`@fonts` in list | ✅ | ❌ | ❌ |
| `decoration-*` in list | ✅ | ✅ | ✅ |
| `name_get()` | ✅ | ⚠️ Deprecated | ❌ |
| `_compute_display_name` | ✅ | ✅ | ✅ |
| `type="json"` controller | ✅ | ❌ | ❌ |
| `type="jsonrpc"` controller | ❌ | ✅ | ✅ |
| `mail.channel` | ✅ | ❌ | ❌ |
| `discuss.channel` | ❌ | ✅ | ✅ |
| Tuple x2many `(0,0,{})` | ✅ | ⚠️ Deprecated | ❌ |
| `Command` objects | ⚠️ Partial | ✅ | ✅ |
| `qweb` manifest key | ✅ | ❌ | ❌ |
| `ir.asset` bundles | ❌ | ✅ | ✅ |
| `ir_property` table | ✅ | ✅ | ❌ |
| JSONB company fields | ❌ | ❌ | ✅ |
| `groups_id` on res.users | ✅ | ✅ | ❌ |
| `group_ids` on res.users | ❌ | ❌ | ✅ |
| `search_fetch()` | ❌ | ❌ | ✅ |
| OWL 2 | ❌ | ✅ | ✅ |
| `t-out` | ❌ | ✅ | ✅ |
| Record rule default (read-only) | ❌ | ✅ | ✅ |
