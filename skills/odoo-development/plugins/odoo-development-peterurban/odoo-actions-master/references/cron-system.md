# ir.cron — Scheduled Actions Architecture

## Table of Contents

1. [What is ir.cron](#what-is-ircron)
2. [Model Fields](#model-fields)
3. [Scheduler Architecture](#scheduler-architecture)
4. [Threading Model](#threading-model)
5. [Error Handling & Auto-Deactivation](#error-handling)
6. [Configuration via UI vs XML](#configuration)
7. [Patterns](#patterns)
8. [Version Differences](#version-differences)

---

## What is ir.cron

`ir.cron` is the Odoo model for scheduled (time-based) actions. Unlike automated actions
(base.automation), cron jobs are not triggered by record events but by TIME.

Each cron job calls a Python method on a specific model at regular intervals.

**When to use cron vs an automated action:**

| Scenario | Cron | Automated Action |
|---|---|---|
| React to a record change | No | Yes |
| Periodic cleanup/sync | Yes | No |
| Batch processing | Yes | Conditionally (on_time) |
| External API polling | Yes | No (except webhook v17+) |
| Reminder before deadline | Both | Both (on_time trigger) |

---

## Model Fields

### Current (v18+)

| Field | Type | Default | Description |
|---|---|---|---|
| name | Char | required | Identifier for logs |
| model_id | Many2one (ir.model) | required | Model with the method |
| method_name | Char | required | Method to call (no arguments) |
| args | Text | `()` | JSON arguments (rarely used) |
| interval_number | Integer | 1 | Frequency — number |
| interval_type | Selection | 'months' | 'minutes', 'hours', 'days', 'weeks', 'months' |
| nextcall | Datetime | required | Next run (UTC!) |
| lastcall | Datetime | auto | Last run |
| active | Boolean | True | Enabled/disabled |
| priority | Integer | 5 | Priority (lower = sooner) |
| user_id | Many2one (res.users) | current | User context for execution |

### Removed in v18+ (were in v8-v17)

| Field | Type | Description | Replacement |
|---|---|---|---|
| numbercall | Integer | Run limit (-1=unlimited) | Logic in the method |
| doall | Boolean | Run missed executions on recovery | Removed, scheduler simplified |

---

## Scheduler Architecture

### How the Odoo scheduler works

```
[Odoo server start]
    ↓
[Scheduler thread(s) start]
    ↓
[Loop: every ~60 seconds]
    ↓
[SELECT FROM ir_cron WHERE active=True AND nextcall <= NOW() ORDER BY priority, id]
    ↓
[For each cron job found:]
    1. Acquire database lock (SELECT ... FOR UPDATE SKIP LOCKED)
    2. Execute method_name on model_id with args
    3. Update nextcall = nextcall + interval
    4. Update lastcall = NOW()
    5. Release lock
    ↓
[Sleep ~60s, repeat]
```

### Nextcall Calculation

```
nextcall = lastcall + (interval_number * interval_type)

Example:
  interval_number = 2
  interval_type = 'hours'
  lastcall = 2025-01-01 10:00:00
  → nextcall = 2025-01-01 12:00:00
```

**Important**: `nextcall` is in UTC! If you set it via the UI, Odoo converts from the user timezone.

### Minimum interval

Technically the minimum is 1 minute, but:
- Below 5 minutes: unstable on SaaS, scheduler polling is ~60s
- Recommended minimum: 5 minutes
- For real-time reactions: use an automated action, not cron

---

## Threading Model

### Configuration

```ini
# odoo.conf
max_cron_threads = 2  # Default: 2 (0 = disabled)
```

- Each cron thread is persistent during job execution
- Threads are pooled — after the job finishes they return to the pool
- On SaaS: controlled by Odoo, cannot be changed

### Concurrent Execution

- One cron job = one thread
- Multiple jobs can run in parallel (up to the max_cron_threads limit)
- The same cron job CANNOT run in parallel — `SELECT FOR UPDATE SKIP LOCKED`
- If a job runs long → it blocks its own next run

### Multi-worker Mode

```ini
# odoo.conf
workers = 4
max_cron_threads = 2
```

In multi-worker mode: cron threads run in ONE of the worker processes (not all of them).
If workers > 0, Odoo picks one worker for cron.

---

## Error Handling

### Failure Tracking

Odoo tracks cron job failures:

1. **3 consecutive errors** → skip the current execution (try later)
2. **5+ errors in 7 days** → AUTO-DEACTIVATION (`active = False`)

### Timeout

- Default timeout: depends on server configuration (`limit_time_real`)
- On SaaS: typically 30-60 seconds
- Timeout = error → counted toward failure tracking

### Error Logging

```python
# In the cron method — ALWAYS log
import logging
_logger = logging.getLogger(__name__)

def _cron_my_job(self):
    try:
        # business logic
        _logger.info('Cron job completed: processed %s records', count)
    except Exception as e:
        _logger.error('Cron job failed: %s', str(e))
        raise  # Re-raise so the scheduler knows about the error
```

### Monitoring

- `Settings → Technical → Scheduled Actions` → see nextcall, lastcall
- Server logs: search for `ir.cron` entries
- On SaaS: `Settings → Technical → Automation → Scheduled Actions`

---

## Configuration

### Via UI (Studio/Settings)

1. `Settings → Technical → Automation → Scheduled Actions`
2. Click "New"
3. Fill in:
   - Name
   - Model (must have the method)
   - Method: method name
   - Interval: number + type
   - Next Execution: when it runs first

### Via XML (in a module)

```xml
<record model="ir.cron" id="cron_cleanup_drafts">
    <field name="name">Cleanup: Archive old drafts</field>
    <field name="model_id" ref="model_sale_order"/>
    <field name="state">code</field>
    <field name="code">model._cron_cleanup_old_drafts()</field>
    <field name="interval_number">1</field>
    <field name="interval_type">days</field>
    <field name="nextcall" eval="(DateTime.now() + timedelta(days=1)).strftime('%Y-%m-%d 02:00:00')"/>
    <field name="active" eval="True"/>
</record>
```

### Via Server Action (SaaS workaround)

On SaaS you cannot create a cron via XML. Alternative:
1. Create a Server Action with Python code
2. Create a Scheduled Action in the UI
3. Set the method: `model.action_server_run()`
4. Or use an Automated Action with an on_time trigger

---

## Patterns

### Simple Cleanup

```python
def _cron_cleanup_old_drafts(self):
    """Archive draft orders older than 30 days"""
    cutoff = fields.Datetime.now() - timedelta(days=30)
    old_drafts = self.search([
        ('state', '=', 'draft'),
        ('create_date', '<', cutoff),
    ])
    if old_drafts:
        old_drafts.write({'active': False})
        _logger.info('Archived %s old draft orders', len(old_drafts))
```

### Batch Processing with Progress

```python
def _cron_sync_external(self):
    """Sync records with external system in batches"""
    batch_size = 200
    domain = [('x_synced', '=', False), ('state', '=', 'confirmed')]
    total = self.search_count(domain)
    processed = 0
    
    while processed < total:
        batch = self.search(domain, limit=batch_size, order='id')
        if not batch:
            break
        
        for rec in batch:
            try:
                # sync logic
                rec.write({'x_synced': True, 'x_sync_date': fields.Datetime.now()})
                processed += 1
            except Exception as e:
                _logger.warning('Sync failed for %s: %s', rec.name, e)
                rec.write({'x_sync_error': str(e)[:200]})
        
        # Commit after each batch (only in cron/module context!)
        self.env.cr.commit()
    
    _logger.info('Synced %s/%s records', processed, total)
```

### Idempotent (Safe to Re-run)

```python
def _cron_generate_invoices(self):
    """Generate invoices for delivered orders without invoice"""
    orders = self.search([
        ('state', '=', 'sale'),
        ('invoice_status', '=', 'to invoice'),
        ('delivery_status', '=', 'full'),
    ])
    
    for order in orders:
        try:
            order._create_invoices()
        except Exception as e:
            _logger.error('Invoice generation failed for %s: %s', order.name, e)
            # Continue with the rest — don't fail the whole batch over one
```

### Run-Once (Replacement for numbercall)

```python
def _cron_one_time_migration(self):
    """One-time data migration — disables itself after run"""
    ICP = self.env['ir.config_parameter'].sudo()
    
    if ICP.get_param('migration_v2_done'):
        return  # Already done
    
    # Do migration work
    records = self.search([('x_old_field', '!=', False)])
    for rec in records:
        rec.write({'x_new_field': rec.x_old_field})
    
    # Mark as done
    ICP.set_param('migration_v2_done', 'True')
    _logger.info('Migration v2 complete: %s records migrated', len(records))
    
    # Optionally deactivate the cron
    cron = self.env.ref('module.cron_one_time_migration', raise_if_not_found=False)
    if cron:
        cron.write({'active': False})
```

---

## Version Differences

### v8-v17: numbercall + doall

```xml
<!-- Old style -->
<record model="ir.cron" id="cron_old_style">
    <field name="numbercall">10</field>  <!-- Run 10x then stop -->
    <field name="doall" eval="True"/>    <!-- Execute missed runs -->
</record>
```

### v18+: Interval only

```xml
<!-- New style — interval only -->
<record model="ir.cron" id="cron_new_style">
    <field name="interval_number">1</field>
    <field name="interval_type">days</field>
    <!-- numbercall and doall do not exist -->
</record>
```

### Migrating numbercall → v18+

If you used `numbercall` for run-once jobs:
1. Use an ICP flag (see the Run-Once pattern above)
2. Or self-deactivate: `cron.write({'active': False})` at the end

If you used `doall` for catch-up after downtime:
1. In the method, process all records whose `nextcall` was skipped
2. Use `lastcall` from the cron record to determine what was missed
