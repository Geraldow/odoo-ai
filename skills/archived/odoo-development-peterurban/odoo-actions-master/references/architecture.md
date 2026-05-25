# Odoo Action Architecture — DB Schema, Dispatch, ORM, Security

## Table of Contents

1. [Database Schema](#database-schema)
2. [Action Dispatch Pipeline](#action-dispatch-pipeline)
3. [ORM Execution Context](#orm-execution-context)
4. [Security Layer](#security-layer)
5. [Model Inheritance](#model-inheritance)

---

## Database Schema

### Core Tables

All action types inherit from a single base table `ir_actions`:

```
ir_actions (base)
├── ir_act_window        → Window actions (views)
├── ir_act_server         → Server actions (Python code)
├── ir_act_report_xml     → Report actions (PDF/HTML)
├── ir_act_url            → URL actions
├── ir_actions_todo       → Configuration wizards
└── ir_cron               → Scheduled actions (cron)
```

### ir_actions (Base Table)

| Column | Type | Description |
|---|---|---|
| id | serial | PK |
| name | varchar | Action name |
| type | varchar | Discriminator: 'ir.actions.act_window', 'ir.actions.server', etc. |
| help | text | Help text (optional) |
| binding_model_id | int (FK) | Model where the action appears in the menu |
| binding_type | varchar | 'action', 'report' |
| binding_view_types | varchar | 'list,form' — where it is shown |

### ir_act_window

| Column | Type | Description |
|---|---|---|
| res_model | varchar | Target model (e.g. 'sale.order') |
| view_mode | varchar | Comma-separated: 'tree,form,kanban,pivot,graph' |
| view_id | int (FK) | Default view |
| search_view_id | int (FK) | Search view |
| domain | text | Filter domain (JSON string) |
| context | text | Context dict (JSON string) |
| target | varchar | 'current', 'new', 'fullscreen', 'main' |
| limit | int | Default page limit |
| groups_id | M2M | Who sees the action |

### ir_act_server

| Column | Type | Description |
|---|---|---|
| model_id | int (FK → ir_model) | Base model of the action |
| state | varchar | 'code', 'object_create', 'object_write', 'multi', 'email', 'followers', 'sms', 'webhook' |
| code | text | Python code (for state='code') |
| child_ids | M2M | Sub-actions (for state='multi') |
| groups_id | M2M (→ res_groups) | Who can run it |
| condition | text | Python condition (default='True') |
| fields_lines | O2M (→ ir.server.object.lines) | Field-value mappings for create/write |

Junction table for child_ids: `rel_server_actions` (server_id, action_id)

### base_automation

| Column | Type | Description |
|---|---|---|
| name | varchar | Rule name |
| model_id | int (FK → ir_model) | Tracked model |
| active | bool | Enabled/disabled |
| trigger | varchar | 'on_create', 'on_write', 'on_create_or_write', 'on_unlink', 'on_change', 'on_time' |
| state | varchar | Action type ('code', 'actions') |
| code | text | Python code |
| action_server_ids | M2M | Server actions to run |
| filter_domain | text | Domain after the operation |
| filter_pre_domain | text | Domain before the operation |
| trigger_field_ids | M2M (→ ir.model.fields) | Tracked fields |
| trg_date_id | int (FK → ir.model.fields) | Date field for on_time |
| trg_date_range | int | Delay value |
| trg_date_range_type | varchar | 'minutes', 'hours', 'days', 'months' |

### ir_cron

| Column | Type | Description |
|---|---|---|
| name | varchar | Identifier |
| model_id | int (FK) | Model containing the method |
| method_name | varchar | Method name to call |
| args | text | JSON arguments |
| interval_number | int | Frequency (default=1) |
| interval_type | varchar | 'minutes', 'hours', 'days', 'weeks', 'months' |
| nextcall | timestamp | Next run (UTC) |
| lastcall | timestamp | Last run |
| numbercall | int | Run limit (-1=unlimited) [REMOVED v18+] |
| doall | bool | Run missed executions [REMOVED v18+] |
| active | bool | Enabled/disabled |

---

## Action Dispatch Pipeline

### Frontend → Backend → Frontend

```
[User clicks button/menu]
        ↓
[Frontend sends RPC: /web/dataset/call_kw]
        ↓
[Backend method executes, returns action dict]
    {'type': 'ir.actions.X', ...}
        ↓
[Frontend action_service routes by type]
        ↓
┌─────────────────────────────────────────────┐
│ act_window → ViewManager renders views      │
│ server    → backend executes, returns next  │
│ report    → generates PDF/HTML, downloads   │
│ act_url   → window.open(url)                │
│ client    → JS registry lookup by tag       │
│ act_multi → sequential execute all actions  │
└─────────────────────────────────────────────┘
```

### Server Action Execution (ir.actions.server.run())

1. `_get_eval_context()` — assembles the globals dict for safe_eval
2. `condition` is evaluated — if False, skip
3. Based on `state`:
   - `code` → `safe_eval(self.code, eval_context, mode='exec')`
   - `multi` → iterates `child_ids`, calls `.run()` on each, returns the last result
   - `object_create` → creates a record per `fields_lines`
   - `object_write` → updates a record per `fields_lines`
   - `email/sms/followers` → delegates to the respective mixin
4. If the code returns an action dict → the frontend dispatches it next

### Automated Action Pipeline (base.automation._process())

```
[ORM operation: create() / write() / unlink()]
        ↓
[Registry check: any base.automation rules for this model?]
        ↓
[For each matching rule:]
    1. Check trigger type matches operation
    2. For on_write: check trigger_field_ids ∩ changed_fields
    3. Evaluate filter_pre_domain against OLD values
    4. Evaluate filter_domain against NEW values
    5. If both pass → execute action with sudo()
        ↓
[Action executes in sudo context]
```

### Return Values

Server action code can return:
- `None` — nothing happens
- An action dict — the frontend runs it (opens a view, downloads a report, etc.)
- Assign to the `action` variable — implicitly returned

```python
# Explicit return (v15+)
action = {'type': 'ir.actions.act_window', 'res_model': 'sale.order', ...}

# display_notification (write-safe — no rollback)
action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {'title': 'OK', 'message': 'Done', 'type': 'success', 'sticky': False}
}
```

---

## ORM Execution Context

### Environment (env)

```python
env.cr        # Database cursor (transaction)
env.uid       # Current user ID (int)
env.user      # Current user record (res.users)
env.context   # Context dict (lang, tz, active_id, ...)
env.company   # Current company (res.company)
env.companies # All allowed companies
```

### Recordset Operations

```python
# CRUD
record = model.create({'name': 'Test'})
records = model.search([('state', '=', 'draft')], limit=10, order='id desc')
records = model.browse([1, 2, 3])
records.write({'state': 'confirmed'})
records.unlink()

# Set operations
union = rs1 | rs2         # Union
intersection = rs1 & rs2  # Intersection
difference = rs1 - rs2    # Difference
is_in = record in records # Membership

# Iteration
for rec in records:
    print(rec.name)

# Mapping / Filtering
names = records.mapped('name')                        # [str, str, ...]
partners = records.mapped('partner_id')               # recordset
expensive = records.filtered(lambda r: r.amount > 1000)
total = records.mapped(lambda r: r.qty * r.price)     # [float, float, ...]
```

### Context Manipulation

```python
# Merge (keeps existing context + adds)
record.with_context(key='value')

# Replace (replaces the entire context)
record.with_context({}, new_key='value')

# Common uses
record.with_context(tracking_disable=True).write(vals)  # Without mail tracking
record.with_context(lang='en_US').name_get()            # English translation
record.with_context(force_company=company_id).create(vals)
```

### sudo() and with_user()

```python
# Superuser — bypasses ACLs and record rules
admin_records = records.sudo()

# Specific user
user_records = records.with_user(user_id)

# sudo() DOES NOT change env.uid for logging — it only bypasses security checks
# Careful: sudo() is "sticky" — once called, all operations on the result are sudo
```

### Raw SQL

```python
# Read-only diagnostics
env.cr.execute("SELECT id, name FROM sale_order WHERE state = 'draft' LIMIT 5")
rows = env.cr.fetchall()  # [(1, 'SO001'), (2, 'SO002'), ...]

# Dictfetch
env.cr.execute("SELECT id, name FROM sale_order LIMIT 5")
rows = env.cr.dictfetchall()  # [{'id': 1, 'name': 'SO001'}, ...]

# CAREFUL: Always invalidate the cache after raw SQL
env.invalidate_all()
```

---

## Security Layer

### ACLs (ir.model.access)

Model-level CRUD permissions. Defined in `security/ir.model.access.csv`:

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_sale_user,sale.order.user,model_sale_order,sales_team.group_sale_salesman,1,1,1,0
access_sale_manager,sale.order.manager,model_sale_order,sales_team.group_sale_manager,1,1,1,1
```

Rules:
- **Additive** (OR): if ANY group grants a permission, the user has it
- **Default-deny**: if no ACL exists for a model, only the superuser (uid=1) has access
- Empty `group_id` = applies to ALL users

### Record Rules (ir.rule)

Record-level filtering. Two types:

**Global rules** (no groups):
- AND between them — ALL must pass
- Restrictive — they narrow access

**Group rules** (with groups):
- OR between them — ANY of them suffices
- Permissive — they widen access

**Combined**: (ALL global) AND (ANY group, or none if the user has no relevant group)

```xml
<!-- See only records of own company -->
<record model="ir.rule" id="rule_sale_company">
    <field name="name">Sale Order: company</field>
    <field name="model_id" ref="model_sale_order"/>
    <field name="domain_force">[('company_id', 'in', company_ids)]</field>
    <field name="perm_read" eval="True"/>
</record>
```

Domain variables in record rules: `user`, `company_ids`, `company_id`, `time`

### Security in the context of actions

| Context | Security |
|---|---|
| Automated action (base.automation) | Runs with `sudo()` — bypasses ACLs and rules |
| Server action — manually triggered | Respects user permissions |
| Server action — via an automated action | Inherits `sudo()` from the automated action |
| Cron job (ir.cron) | Runs as superuser (uid=1) |
| Python code with `sudo()` | Bypasses security, but NOT SQL constraints |

---

## Model Inheritance

### Classical (_inherit)

Extends an existing model. Same DB table.

```python
class SaleOrderExtended(models.Model):
    _inherit = 'sale.order'
    x_custom = fields.Char('Custom Field')
    
    def action_confirm(self):
        # Override + super()
        res = super().action_confirm()
        self.x_custom = 'confirmed'
        return res
```

### Delegation (_inherits)

New table, transparent access to parent fields.

```python
class Student(models.Model):
    _name = 'school.student'
    _inherits = {'res.partner': 'partner_id'}
    partner_id = fields.Many2one('res.partner', required=True, ondelete='cascade')
    grade = fields.Char()
    # student.name → transparently reads from res.partner
```

### Abstract (_inherit without _name)

Mixin without its own table.

```python
class MailThread(models.AbstractModel):
    _name = 'mail.thread'
    # Shares methods and fields, but has no table of its own
```

### Practical impact on actions

- Classical inheritance: An automated action on `sale.order` also captures custom fields from extensions
- Delegation: An automated action on `school.student` DOES NOT SEE changes on `res.partner` directly — the trigger must be placed on both models
- Studio fields (`x_studio_*`): They use classical inheritance under the hood — they work normally in automated actions
