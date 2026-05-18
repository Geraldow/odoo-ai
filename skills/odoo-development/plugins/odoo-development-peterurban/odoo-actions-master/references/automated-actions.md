# Automated Actions (base.automation) — Triggers, Filtering, Execution, Studio

## Table of Contents

1. [What is base.automation](#what-is-base-automation)
2. [Trigger Types](#trigger-types)
3. [Domain Filtering](#domain-filtering)
4. [Action Types](#action-types)
5. [Studio UI](#studio-ui)
6. [Studio vs Technical Menu](#studio-vs-technical-menu)
7. [Studio Limitations & Workarounds](#studio-limitations)
8. [Best Practices](#best-practices)
9. [Debugging](#debugging)

For footguns (infinite loops, O2M trigger trap, UserError rollback, mail.message
automation, Studio field-name collisions) see **[anti-patterns.md](anti-patterns.md)**.

---

## What is base.automation

`base.automation` is a model that "listens" to ORM operations (create, write, unlink, form change,
time conditions) and automatically runs actions. Under the hood it hooks into the model's ORM
methods when a rule is registered and invokes the action when the conditions are met.

Module: `base_automation` (must be installed; it is installed by default in Enterprise/SaaS)

Key difference from `ir.actions.server`: An automated action runs AUTOMATICALLY based on
an event. A server action runs MANUALLY (button, menu) or is invoked from an automated action.

---

## Trigger Types

### on_create

**When**: A new record is created and saved (after the `create()` commit)

```
Used for: Initialization, default values, notifications on creation
Context: records = the newly created record(s)
Trigger fields: Not relevant
```

Example: New sales order → automatically assign a sales team based on the partner.

### on_write

**When**: An existing record is saved and the tracked fields have changed

```
Used for: Reaction to a state change, cascading field updates
Context: records = the modified record(s)
Trigger fields: REQUIRED — you must select at least one field
```

**Important**: If you don't select trigger fields, the action may fire on EVERY write, which is a
performance disaster.

Example: `state` changes to 'confirmed' → create a delivery order.

### on_create_or_write

**When**: Combination of on_create + on_write

```
Used for: When you want the same logic for create and write
Trigger fields: Relevant for the write part
```

### on_unlink

**When**: A record is deleted (after `unlink()`)

```
Used for: Cleanup, audit logging, cascade operations
Context: records = records before deletion (still in memory)
Note: Rarely used — Odoo prefers archiving over deleting
```

### on_change / on_form_change (v17+: "On UI Change")

**When**: A field changes on a form in the UI, BEFORE save

```
Used for: Real-time UI feedback, dynamic default values
Trigger fields: REQUIRED
Limitations:
  - Works ONLY in the UI (not via API, import, cron)
  - Works ONLY with action type "Execute Python Code"
  - Does not fire if the field was changed by ANOTHER automated action
  - In v17+ renamed to "Based on Form Modification" / "On UI Change"
```

### on_time / based_on_time_condition

**When**: A date field + delay reaches the current time

```
Used for: Reminders, expiration, auto-archiving, follow-up
Configuration:
  trg_date_id = date field (e.g. 'date_deadline')
  trg_date_range = number (e.g. 3)
  trg_date_range_type = 'days' / 'hours' / 'minutes' / 'months'
Scheduler: Runs periodically (default ~4h, more often for <40h delays)
Limitations: Works ONLY with the "Execute Python Code" action type
```

A negative `trg_date_range` = before the date (e.g. -2 days = 2 days before the deadline).

---

## Domain Filtering

Automated actions have TWO domain filters, which allows capturing STATE TRANSITIONS:

### filter_pre_domain (Before Update Domain)

Evaluated against the record's OLD values (before the operation).

```python
# Example: Only if state was 'draft' before the change
[('state', '=', 'draft')]
```

### filter_domain (After Update Domain)

Evaluated against the record's NEW values (after the operation).

```python
# Example: Only if state is now 'confirmed'
[('state', '=', 'confirmed')]
```

### State Transition Pattern

Combination of both to capture a transition:

```
filter_pre_domain: [('state', '=', 'draft')]
filter_domain:     [('state', '=', 'confirmed')]
→ Fires ONLY when state changes from 'draft' to 'confirmed'
```

This is the most common pattern and the main reason both filters exist.

### Domain Syntax Gotchas

```python
# AND (default) — all conditions must hold
[('state', '=', 'draft'), ('amount', '>', 100)]

# OR — prefix operator
['|', ('state', '=', 'draft'), ('state', '=', 'sent')]

# NOT
['!', ('active', '=', False)]

# Nested OR with multiple conditions (careful with the number of operators!)
# 3 conditions = 2x '|'
['|', '|', ('state', '=', 'a'), ('state', '=', 'b'), ('state', '=', 'c')]

# Field-to-field compare IS NOT POSSIBLE in a domain!
# WRONG: [('date_done', '<=', 'commitment_date')]
# Workaround: computed stored field or Python code
```

---

## Action Types

### Update Record
Sets field values on the current or a related record.
- Direct value, reference, Python expression
- Multiple fields at once

### Create a New Record
Creates a record on any model.
- Link Field to connect to the trigger record
- **Limitation**: Does not set mandatory fields if the model has constraints → use Python code

### Execute Python Code
The most flexible type. Runs Python in the safe_eval context.

Available variables:
```python
records        # Recordset of the trigger record(s)
record         # Alias for records (if singleton)
env            # Odoo environment
model          # Model instance
time           # time module
datetime       # datetime module
dateutil       # dateutil module
timezone       # pytz timezone
float_compare  # Float comparison utility
log()          # Logging (server logs)
_logger        # Logger instance
UserError      # Exception for user-facing errors (CAUSES ROLLBACK!)
Command        # x2m command helper (v16+)
```

### Send Email / Send SMS / Post Message
Uses email/SMS templates. Variants:
- Email (SMTP)
- Message (Discuss — followers see it)
- Note (internal — internal users only)
- SMS (with or without note)

### Add Followers
Adds/removes followers on a record.

### Create Activity
Creates an activity (task) for a specific user.

### Webhook (v17+)
Sends a POST request to an external URL with a JSON payload.
Configuration: URL + selection of fields for the payload.

---

## Studio UI

### Creating an Automated Action via Studio

1. Open the model in Studio (Studio icon in the navbar)
2. Click **Automations** (or Automation Rules)
3. Click **New**
4. Configure:
   - **Name**: Name the rule
   - **Model**: Auto-filled based on where you are
   - **Trigger**: Choose the type (On Creation, On Update, etc.)
   - **Trigger Fields**: If on_write, pick the fields
   - **Apply on**: Domain filter (visual builder)
   - **Before Update Domain**: Domain before the operation
   - **Action To Do**: Choose the action type
5. If Python code → write the code in the Code editor
6. **Notes** tab → document what the action does

### Studio Automated Action vs Settings > Technical

| Feature | Studio | Technical Menu |
|---|---|---|
| Visual condition builder | Yes | No (raw domain) |
| Drag-drop trigger field selection | Yes | Dropdown |
| Code editor syntax highlighting | Basic | Basic |
| All trigger types | Yes | Yes |
| All action types | Yes | Yes |
| Webhook configuration | Yes (v17+) | Yes (v17+) |
| Batch edit multiple rules | No | Yes (list view) |
| Copy/duplicate rule | Yes | Yes |
| Export/import | No (DB only) | Yes (via module XML) |
| Version control | No | Yes (git) |

---

## Studio vs Technical Menu

### What Studio DOES better
- Visual field placement (drag-drop)
- Simple automations without code
- Quick prototyping — no server restart
- Non-developer friendly
- Approval workflows (Enterprise)

### What the Technical Menu DOES better
- Full Python access (in custom modules, not safe_eval)
- Version control (git)
- Replicability across instances
- Complex computed fields
- Custom models from scratch
- Scheduled actions (cron) — Studio has no direct cron UI
- Performance-critical logic

### When to use what

```
Simple: "When state changes to confirmed, send an email"
→ STUDIO — 5 minutes, no code

Medium: "When an SO over 10k€ is created, create a task in the project and add the manager as a follower"
→ STUDIO with Python code — 15 minutes

Complex: "Cross-module workflow with conditional branching, external API calls, heavy computation"
→ CUSTOM MODULE — Studio hits the safe_eval limits here
```

---

## Studio Limitations

### Functional limits

1. **Python** — no imports, safe_eval sandbox, no `__dunder__` access
2. **Create Record** — cannot handle mandatory fields with constraints → use Python `env['model'].create({...})`
3. **on_change** — does not work when the field is changed by ANOTHER automation → cannot be chained via on_change
4. **Cascading** — no built-in protection against infinite loops
5. **Complex computed fields** — Studio does not allow `@api.depends()` or store=True with custom logic
6. **Export** — Studio customizations live in the DB, not in files → cannot be version-controlled

### Known problems

(See **[anti-patterns.md](anti-patterns.md)** for full write-ups: field-name
collisions, performance, silent failures, mail recursion.)

### Workarounds

```python
# Delete record (not possible via the UI "Create Record" action)
for record in records:
    record.unlink()

# Set mandatory fields (work around the Create Record limitation)
env['project.task'].create({
    'name': record.name,
    'project_id': env.ref('project.default_project').id,  # mandatory
})

# Guard against cascading
if env.context.get('skip_automation'):
    pass  # skip
else:
    record.with_context(skip_automation=True).write({'state': 'done'})

# Anti-infinite-loop flag
if not env.context.get('from_automation'):
    record.with_context(from_automation=True).write({'field': 'value'})
```

---

## Best Practices

### 1. ALWAYS document
The Notes tab exists — use it. Who created it, when, why, what it does.

### 2. Be selective with trigger fields
For on_write ALWAYS select specific fields. Never leave empty — the action will fire
on EVERY save.

### 3. Use domain filters
Without a filter the action runs on EVERY record. Always add `filter_domain` to narrow it down.

### 4. Test on non-critical data
Create a test record, run the action, verify the result. The Network tab in DevTools = the real error.

### 5. One purpose = one action
Don't build a mega-action that does 10 things. Split into several simple actions.

### 6. Watch performance
An automated action on `sale.order.line` with an on_write trigger without a filter = fires on
EVERY save of EVERY line. With 500 lines = 500 executions.

### 7. Scheduled actions = stagger
If you have multiple cron jobs, don't set them all to the same time. Spread them out.

---

## Debugging

### Server logs
Automated actions log to the server logs. Look for:
```
base.automation: ... rule triggered
base.automation: ... executing action
```

### Network tab (UI crash)
DevTools → Network → the last RPC request `/web/dataset/call_kw` → Response payload
contains the real traceback.

### Testing strategy
1. Create a test record
2. Perform the operation that should trigger the action
3. Verify the result (field value, created record, email sent)
4. If nothing → check:
   - Is the action active?
   - Does the trigger type match the operation?
   - Are the trigger fields correct?
   - Do the domain filters pass?
   - Is there an error in the Python code? (check server logs)
