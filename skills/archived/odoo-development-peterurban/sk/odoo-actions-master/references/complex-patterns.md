# Komplexné action patterny — chaining, webhooky, multi-step, gotchas

## Obsah

1. [Action chaining](#action-chaining)
2. [Multi-step patterny](#multi-step-patterny)
3. [Webhook integrácia (v17+)](#webhook-integracia-v17)
4. [State machine pattern](#state-machine-pattern)
5. [Cross-model operácie](#cross-model-operacie)
6. [Context passing](#context-passing)
7. [Error handling](#error-handling)
8. [Produkčné patterny](#produkcne-patterny)

Pre footguny (infinite loops, O2M trigger trap, UserError rollback,
mail.message automatizácia, kolízie Studio field, cron quirks) pozri
**[anti-patterns.md](anti-patterns.md)**.

---

## Action chaining

### Server action volá ďalšiu server action

```python
# V server action kóde:
other_action = env.ref('module.action_xml_id', raise_if_not_found=False)
if other_action:
    other_action.with_context(active_id=record.id, active_ids=record.ids).run()
```

### Multi-akcia (state='multi')

Server action so `state='multi'` spúšťa `child_ids` sekvenčne. Posledný return value
sa vráti na frontend.

```xml
<!-- V module XML -->
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

### ir.actions.act_multi (frontend reťazec)

Frontend spustí viacero akcií sekvenčne:

```python
# Vráti z Python metódy:
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

## Multi-step patterny

### Write + otvorenie formulára

```python
# Zapíš zmeny a otvor formulár
record.write({'state': 'confirmed'})

action = {
    'type': 'ir.actions.act_window',
    'res_model': record._name,
    'res_id': record.id,
    'view_mode': 'form',
    'target': 'current',
}
```

### Write + otvorenie wizardu

```python
# Zapíš, potom otvor wizard
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

### Create + otvorenie vytvoreného záznamu

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

### Podmienený return akcie

```python
# Rôzna akcia podľa stavu
if record.amount_total > 10000:
    # Otvor approval wizard
    action = {
        'type': 'ir.actions.act_window',
        'res_model': 'sale.approval.wizard',
        'view_mode': 'form',
        'target': 'new',
        'context': {'default_order_id': record.id},
    }
else:
    # Len notifikácia
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

## Webhook integrácia (v17+)

### Outbound webhook (Odoo → externý systém)

Cez automated action s action type "Webhook":
1. Nastav URL endpoint
2. Vyber polia do JSON payloadu
3. Trigger: akýkoľvek (on_create, on_write, atď.)
4. Odoo pošle POST request s JSON payloadom

### Inbound webhook (externý systém → Odoo)

Od v17+, automated action môže mať trigger type "Webhook":
1. Odoo vygeneruje unikátny webhook URL
2. Externý systém pošle POST na tento URL
3. Payload sa spracuje a spustí akciu

### Pattern webhook Python code

```python
# V automated action s webhook triggerom
# payload je dostupný v kontexte
payload = env.context.get('webhook_payload', {})

if payload.get('event') == 'payment_received':
    order = env['sale.order'].search([
        ('name', '=', payload.get('reference'))
    ], limit=1)
    if order:
        order.write({'x_studio_payment_status': 'received'})
```

### Outbound webhook cez Python code (manuálne)

```python
# POZOR: requests modul NIE JE dostupný v safe_eval!
# Na SaaS/Studio toto nefunguje.
# Iba v custom module:
import requests
response = requests.post('https://api.example.com/webhook', json={
    'order': record.name,
    'amount': record.amount_total,
})
```

Pre SaaS: použi built-in Webhook action type alebo Odoo.sh pre custom modules.

---

## State machine pattern

Najčastejší use case — automatický prechod stavov:

### Konfigurácia

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

### Viacstupňové s časovými podmienkami

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

## Cross-model operácie

### Vytvor súvisiaci záznam na inom modeli

```python
# Z sale.order vytvor project.task
task = env['project.task'].sudo().create({
    'name': 'Implement: %s' % record.name,
    'project_id': env['project.project'].search([
        ('name', '=', 'Implementation')
    ], limit=1).id,
    'partner_id': record.partner_id.id,
    'description': 'SO: %s\nAmount: %s' % (record.name, record.amount_total),
})

# Ulož referenciu späť
record.write({'x_studio_task_id': task.id})
```

### Agregácia z child na parent

```python
# Automated action na sale.order.line (trigger: on_write, field: price_subtotal)
# Updatne custom pole na parent sale.order

order = record.order_id
total_discount = sum(line.discount for line in order.order_line)
order.write({'x_studio_total_discount': total_discount})
```

### Cross-company operácie

```python
# Pozor na multi-company pravidlá!
# sudo() obchádza record rules, ale company context môže filtrovať
target_company = env['res.company'].sudo().search([('name', '=', 'SubCompany')], limit=1)
if target_company:
    env['purchase.order'].sudo().with_company(target_company).create({
        'partner_id': record.partner_id.id,
        'company_id': target_company.id,
    })
```

---

## Context passing

### Default hodnoty cez context

```python
# Otvor form s predvyplnenými hodnotami
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

### Context medzi reťazenými akciami

```python
# Action 1: Nastav context
record.with_context(
    processed_by='automation',
    original_state=record.state,
).write({'state': 'processing'})

# V Action 2 (triggered by write above):
original = env.context.get('original_state')
if original == 'draft':
    # Logic for draft → processing transition
    pass
```

---

## Error handling

### Safe error pattern (read-only diagnostika)

```python
output = []
try:
    orders = env['sale.order'].search([('state', '=', 'draft')], limit=5)
    for order in orders:
        output.append('%s: %s EUR' % (order.name, order.amount_total))
except Exception as e:
    output.append('ERROR: %s' % str(e)[:200])

raise UserError('\n'.join(output))  # ROLLBACK — ale pre read-only to nevadí
```

### Safe error pattern (write operácie)

```python
# NIKDY raise UserError po write — spôsobí ROLLBACK!
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

### Try/except v automated actions

```python
# V automated actions je TRY/EXCEPT kritický
# Uncaught exception v on_create automated action na mail.message → rozbije catchall!
try:
    # tvoja logika
    record.write({'x_studio_processed': True})
except Exception as e:
    # Log ale neprerušuj flow
    log('Automation error on %s: %s' % (record.id, str(e)[:200]), level='error')
```

---

## Produkčné patterny

### Pattern batch processing

```python
# Spracuj záznamy v batch-och aby si nepreťažil pamäť
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
    # Commit po každom batchi (iba v module/cron, NIE v safe_eval!)
    # env.cr.commit()

log('Confirmed %s orders' % total)
```

### Pattern idempotentnej akcie

```python
# Akcia ktorá sa môže spustiť viackrát bez negatívnych efektov
if not record.x_studio_task_id:  # Guard — ak task ešte neexistuje
    task = env['project.task'].sudo().create({
        'name': record.name,
        'project_id': PROJECT_ID,
    })
    record.write({'x_studio_task_id': task.id})
# Ak task existuje, nič sa nestane → safe to re-run
```

### Pattern audit log

```python
# Loguj zmeny pre audit trail
body = 'Automation: State changed from %s to %s by %s' % (
    env.context.get('old_state', '?'),
    record.state,
    env.user.name,
)
record.message_post(body=body, message_type='comment', subtype_xmlid='mail.mt_note')
```

### Pattern scheduled cleanup (pre cron)

```python
# V module kóde (nie safe_eval — cron volá metódu):
def _cron_cleanup_drafts(self):
    cutoff = fields.Datetime.now() - timedelta(days=30)
    old_drafts = self.search([
        ('state', '=', 'draft'),
        ('create_date', '<', cutoff),
    ])
    old_drafts.write({'active': False})  # Archive, nemazať
    _logger.info('Archived %s old draft orders', len(old_drafts))
```
