# Complex Action Patterns — Chaining, Webhooks, Multi-Step, Gotchas

## Table of Contents

1. [Action Chaining](#action-chaining)
2. [Multi-Step Patterns](#multi-step-patterns)
3. [Webhook Integration (v17+)](#webhook-integration)
4. [State Machine Pattern](#state-machine-pattern)
5. [Cross-Model Operations](#cross-model-operations)
6. [Context Passing](#context-passing)
7. [Error Handling](#error-handling)
8. [Production Patterns](#production-patterns)

For footguns (infinite loops, O2M trigger trap, UserError rollback,
mail.message automation, Studio field collisions, cron quirks) see
**[anti-patterns.md](anti-patterns.md)**.

---

## Action Chaining

### Server Action calls another Server Action

```python
# In server action code:
other_action = env.ref('module.action_xml_id', raise_if_not_found=False)
if other_action:
    other_action.with_context(active_id=record.id, active_ids=record.ids).run()
```

### Multi-action (state='multi')

A server action with `state='multi'` runs `child_ids` sequentially. The last return value
is returned to the frontend.

```xml
<!-- In module XML -->
<record model="ir.actions.server" id="action_multi_step">
    <field name="name">Multi-Step Process</field>
    <field name="model_id" ref="model_sale_order"/>
    <field name="state">multi</field>
    <field name="child_ids" eval="[(6, 0, [
        ref('action_step_1'),
        ref('action_step_2'),
        ref('action_step_3'),
    ])]"/>
</record>
```

### ir.actions.act_multi (frontend chain)

The frontend runs several actions sequentially:

```python
# Return from a Python method:
return {
    'type': 'ir.actions.act_multi',
    'actions': [
        {'type': 'ir.actions.act_window_close'},
        {'type': 'ir.actions.client', 'tag': 'reload'},
        {
            'type': 'ir.actions.act_window',
            'res_model': 'sale.order',
            'view_mode': 'form',
            'res_id': record.id,
        }
    ]
}
```

---

## Multi-Step Patterns

### Write + Open Form

```python
# Write changes and open the form
record.write({'state': 'confirmed'})

action = {
    'type': 'ir.actions.act_window',
    'res_model': record._name,
    'res_id': record.id,
    'view_mode': 'form',
    'target': 'current',
}
```

### Write + Open Wizard

```python
# Write, then open a wizard
record.write({'processing': True})

action = {
    'type': 'ir.actions.act_window',
    'res_model': 'sale.advance.payment.inv',
    'view_mode': 'form',
    'target': 'new',
    'context': {
        'active_id': record.id,
        'active_ids': record.ids,
        'active_model': record._name,
        'default_advance_payment_method': 'delivered',
    }
}
```

### Create + Open Created Record

```python
new_record = env['project.task'].create({
    'name': 'Task from %s' % record.name,
    'project_id': env.ref('project.default_project', raise_if_not_found=False).id or False,
    'partner_id': record.partner_id.id,
})

action = {
    'type': 'ir.actions.act_window',
    'res_model': 'project.task',
    'res_id': new_record.id,
    'view_mode': 'form',
    'target': 'current',
}
```

### Conditional Action Return

```python
# Different action depending on state
if record.amount_total > 10000:
    # Open approval wizard
    action = {
        'type': 'ir.actions.act_window',
        'res_model': 'sale.approval.wizard',
        'view_mode': 'form',
        'target': 'new',
        'context': {'default_order_id': record.id},
    }
else:
    # Just a notification
    action = {
        'type': 'ir.actions.client',
        'tag': 'display_notification',
        'params': {
            'title': 'Auto-approved',
            'message': 'Order %s auto-approved (under threshold)' % record.name,
            'type': 'success',
            'sticky': False,
        }
    }
```

---

## Webhook Integration (v17+)

### Outbound Webhook (Odoo → External)

Via an automated action with action type "Webhook":
1. Set the URL endpoint
2. Pick fields for the JSON payload
3. Trigger: any (on_create, on_write, etc.)
4. Odoo sends a POST request with the JSON payload

### Inbound Webhook (External → Odoo)

Since v17+, an automated action can have trigger type "Webhook":
1. Odoo generates a unique webhook URL
2. The external system sends a POST to this URL
3. The payload is processed and the action runs

### Webhook Python Code Pattern

```python
# In an automated action with a webhook trigger
# the payload is available in the context
payload = env.context.get('webhook_payload', {})

if payload.get('event') == 'payment_received':
    order = env['sale.order'].search([
        ('name', '=', payload.get('reference'))
    ], limit=1)
    if order:
        order.write({'x_studio_payment_status': 'received'})
```

### Outbound Webhook via Python Code (manual)

```python
# CAREFUL: the requests module IS NOT available in safe_eval!
# This does not work on SaaS/Studio.
# Only in a custom module:
import requests
response = requests.post('https://api.example.com/webhook', json={
    'order': record.name,
    'amount': record.amount_total,
})
```

For SaaS: use the built-in Webhook action type or Odoo.sh for custom modules.

---

## State Machine Pattern

The most common use case — automatic state transitions:

### Configuration

```
Automated Action: "Draft → Confirmed auto-transition"
Model: sale.order
Trigger: on_write
Trigger Fields: [amount_total, partner_id]
Before Update Domain: [('state', '=', 'draft')]
Filter Domain: [('state', '=', 'draft'), ('amount_total', '>', 0), ('partner_id', '!=', False)]

Python Code:
for rec in records:
    rec.action_confirm()
```

### Multi-stage with time-based conditions

```
Action 1: "Confirmed → Sent (after 1 day)"
Trigger: on_time
Date Field: confirmation_date
Delay: 1 day
Filter Domain: [('state', '=', 'sale')]

Action 2: "Sent → Overdue (after 30 days)"  
Trigger: on_time
Date Field: date_order
Delay: 30 days
Filter Domain: [('state', '=', 'sale'), ('invoice_status', '!=', 'invoiced')]
```

---

## Cross-Model Operations

### Create a related record on another model

```python
# From sale.order create a project.task
task = env['project.task'].sudo().create({
    'name': 'Implement: %s' % record.name,
    'project_id': env['project.project'].search([
        ('name', '=', 'Implementation')
    ], limit=1).id,
    'partner_id': record.partner_id.id,
    'description': 'SO: %s\nAmount: %s' % (record.name, record.amount_total),
})

# Store the reference back
record.write({'x_studio_task_id': task.id})
```

### Aggregation from child to parent

```python
# Automated action on sale.order.line (trigger: on_write, field: price_subtotal)
# Updates a custom field on the parent sale.order

order = record.order_id
total_discount = sum(line.discount for line in order.order_line)
order.write({'x_studio_total_discount': total_discount})
```

### Cross-company operations

```python
# Watch out for multi-company rules!
# sudo() bypasses record rules, but the company context may filter
target_company = env['res.company'].sudo().search([('name', '=', 'SubCompany')], limit=1)
if target_company:
    env['purchase.order'].sudo().with_company(target_company).create({
        'partner_id': record.partner_id.id,
        'company_id': target_company.id,
    })
```

---

## Context Passing

### Default values via context

```python
# Open a form with pre-filled values
action = {
    'type': 'ir.actions.act_window',
    'res_model': 'account.move',
    'view_mode': 'form',
    'target': 'current',
    'context': {
        'default_partner_id': record.partner_id.id,
        'default_move_type': 'out_invoice',
        'default_invoice_origin': record.name,
        'default_invoice_line_ids': [(0, 0, {
            'product_id': line.product_id.id,
            'quantity': line.product_uom_qty,
            'price_unit': line.price_unit,
        }) for line in record.order_line],
    }
}
```

### Context between chained actions

```python
# Action 1: Set context
record.with_context(
    processed_by='automation',
    original_state=record.state,
).write({'state': 'processing'})

# In Action 2 (triggered by the write above):
original = env.context.get('original_state')
if original == 'draft':
    # Logic for draft → processing transition
    pass
```

---

## Error Handling

### Safe error pattern (read-only diagnostics)

```python
output = []
try:
    orders = env['sale.order'].search([('state', '=', 'draft')], limit=5)
    for order in orders:
        output.append('%s: %s EUR' % (order.name, order.amount_total))
except Exception as e:
    output.append('ERROR: %s' % str(e)[:200])

raise UserError('\n'.join(output))  # ROLLBACK — but that's fine for read-only
```

### Safe error pattern (write operations)

```python
# NEVER raise UserError after a write — it causes a ROLLBACK!
errors = []
success_count = 0

for rec in env['sale.order'].search([('state', '=', 'draft')]):
    try:
        rec.action_confirm()
        success_count += 1
    except Exception as e:
        errors.append('%s: %s' % (rec.name, str(e)[:100]))

message = 'Confirmed: %s orders' % success_count
if errors:
    message += '\nErrors:\n' + '\n'.join(errors)

action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {
        'title': 'Batch Confirmation',
        'message': message,
        'type': 'warning' if errors else 'success',
        'sticky': True,
    }
}
```

### Try/except in automated actions

```python
# In automated actions TRY/EXCEPT is critical
# An uncaught exception in an on_create automated action on mail.message → breaks the catchall!
try:
    # your logic
    record.write({'x_studio_processed': True})
except Exception as e:
    # Log but don't break the flow
    log('Automation error on %s: %s' % (record.id, str(e)[:200]), level='error')
```

---

## Production Patterns

### Batch Processing Pattern

```python
# Process records in batches to avoid memory pressure
batch_size = 100
offset = 0
total = 0

while True:
    batch = env['sale.order'].search(
        [('state', '=', 'draft'), ('amount_total', '>', 0)],
        limit=batch_size,
        offset=offset,
        order='id'
    )
    if not batch:
        break
    
    for rec in batch:
        rec.action_confirm()
        total += 1
    
    offset += batch_size
    # Commit after each batch (only in module/cron, NOT in safe_eval!)
    # env.cr.commit()

log('Confirmed %s orders' % total)
```

### Idempotent Action Pattern

```python
# An action that can run multiple times without negative effects
if not record.x_studio_task_id:  # Guard — if the task does not yet exist
    task = env['project.task'].sudo().create({
        'name': record.name,
        'project_id': PROJECT_ID,
    })
    record.write({'x_studio_task_id': task.id})
# If the task exists, nothing happens → safe to re-run
```

### Audit Log Pattern

```python
# Log changes for audit trail
body = 'Automation: State changed from %s to %s by %s' % (
    env.context.get('old_state', '?'),
    record.state,
    env.user.name,
)
record.message_post(body=body, message_type='comment', subtype_xmlid='mail.mt_note')
```

### Scheduled Cleanup Pattern (for cron)

```python
# In module code (not safe_eval — cron calls a method):
def _cron_cleanup_drafts(self):
    cutoff = fields.Datetime.now() - timedelta(days=30)
    old_drafts = self.search([
        ('state', '=', 'draft'),
        ('create_date', '<', cutoff),
    ])
    old_drafts.write({'active': False})  # Archive, don't delete
    _logger.info('Archived %s old draft orders', len(old_drafts))
```
