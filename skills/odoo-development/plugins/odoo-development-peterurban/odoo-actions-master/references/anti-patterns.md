# Action System Anti-Patterns & Gotchas

Consolidated list of action-system footguns that surface in automated actions,
server actions, and cron jobs. Each entry shows the wrong way, the reason it
fails, and the correct pattern.

---

## 1. `raise UserError` after a write

**Symptom:** The server action reports success but the data change never persists.

**Cause:** `UserError` aborts the transaction. Any `write()` / `create()` / `unlink()`
that ran before the raise is rolled back.

```python
# WRONG — write is discarded
record.write({'state': 'confirmed'})
raise UserError('Confirmed!')
```

```python
# RIGHT — use display_notification for toast feedback on writes
record.write({'state': 'confirmed'})
action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {'title': 'Confirmed', 'message': record.name, 'type': 'success'},
}
```

When a rollback is what you want (e.g. a "test write without persisting" pattern),
the `UserError`-after-write behavior is intentional — see the safe rollback
pattern in the odoo-server-actions skill.

---

## 2. Infinite automation loop

**Symptom:** A write triggers an automated action, which writes again, which
triggers another automated action, which writes the original field again…

**Cause:** No built-in cycle protection between `base.automation` rules.

```python
# Rule A (on_write, field=state): sets state = 'confirmed'
# Rule B (on_write, field=state): sets state = 'processing' —
# re-triggers Rule A's filter, infinite loop.
```

```python
# RIGHT — guard with context key
if env.context.get('skip_auto'):
    # We're already inside an automation; bail out
    return
record.with_context(skip_auto=True).write({'state': 'confirmed'})
```

Pair the guard with a domain filter so the rule ALSO short-circuits when the
state is already the target value — the cheapest filter wins.

---

## 3. O2M trigger trap (parent doesn't see child changes)

**Symptom:** Automated action on `sale.order` with trigger fields
`[order_line]` doesn't fire when a line is added / edited.

**Cause:** `on_write` fires for the record whose `write()` was called. Adding
or editing an O2M line writes to the child model (`sale.order.line`), not
the parent. The parent's `write()` is not invoked.

```python
# WRONG — automation on sale.order won't catch edits to its lines
# Trigger: on_write, fields: [order_line]
```

```python
# RIGHT — put the automation on the child model and propagate up
# Automation on sale.order.line, trigger: on_write, fields: [price_subtotal]
# Code:
order = records.order_id
order.write({'x_studio_lines_changed': True})
# Then attach a second automation to sale.order that reacts to
# x_studio_lines_changed if needed.
```

---

## 4. `mail.message` automation breaking the mail gateway

**Symptom:** Incoming emails stop being processed. `mailgateway` logs
uncaught exceptions.

**Cause:** Automated action on `mail.message` with trigger `on_create`. Any
uncaught exception propagates up through `mail.thread.message_post()` into
`mail.gateway.process()`, which the catchall relies on.

```python
# WRONG — no guard around automation body
record.write({'x_processed': True})
# If the above raises (e.g. record locked, bad value), catchall is dead.
```

```python
# RIGHT — always swallow exceptions on mail.message automations
try:
    record.write({'x_processed': True})
except Exception:
    # Prefer a silent fail to breaking incoming email
    pass
```

Better alternative: put the logic on a more specific model (`mail.message` via
`model` filter is often overkill) or use `ir.cron` to batch-process messages
outside the gateway hot path.

---

## 5. Unfiltered automation on a high-traffic model

**Symptom:** Save latency grows. Cron/background jobs start timing out. Users
complain forms take seconds to save.

**Cause:** Automated action on `res.partner`, `sale.order.line`,
`account.move.line`, or similar — no `filter_domain`. The rule re-evaluates
on every single write.

```python
# WRONG — fires on every partner save. With 50k partners, every automation
# on the partner becomes a bottleneck.
# filter_domain: []
```

```python
# RIGHT — narrow with a cheap domain
# filter_domain: [('customer_rank', '>', 0), ('x_studio_needs_review', '=', True)]
```

Order domain leaves by selectivity: the cheapest discriminator first, so most
records short-circuit before expensive joins.

---

## 6. Missing trigger fields on `on_write`

**Symptom:** Same as #5 — automation runs on every save.

**Cause:** On trigger `on_write`, leaving trigger fields empty means *any*
field change re-evaluates the rule.

Fix: always pick the smallest set of fields whose change actually matters for
this rule. For `on_create_or_write`, trigger fields apply to the write branch.

---

## 7. `on_change` / `on_form_change` doesn't run outside the UI

**Symptom:** Automation works when users edit in the UI but not during imports,
API writes, or other automations.

**Cause:** `on_change` is a UI-only trigger — it fires during form rendering,
not during ORM `write()`.

Fix: if you need the logic in both contexts, use `on_write` for ORM and
duplicate a lighter version as `on_change` for UI feedback. Or put the logic
in a `@api.constrains` / `@api.depends` in a custom module.

---

## 8. Wizard default passed as single `res_id` in Odoo 19+

**Symptom:** Opening a wizard from an action raises `ValueError` in Odoo 19.

**Cause:** In 19, wizard defaults expect `default_res_ids` (list). Passing
`default_res_id` (int) is deprecated and may raise depending on the model.

```python
# WRONG (v19+) — may ValueError
action = {'context': {'default_res_id': record.id}}
```

```python
# RIGHT — list form works in 18 and 19
action = {'context': {'default_res_ids': record.ids}}
```

---

## 9. `sudo()` bypasses everything — including company scoping

**Symptom:** Records appear cross-company, a check you expected (record rule)
silently does not apply.

**Cause:** `sudo()` ignores ACLs *and* record rules. Company filtering lives
in record rules — so sudo'd searches see all companies.

Fix: use `with_company()` to set the company explicitly, or combine
`sudo().with_company(target)` to keep the sudo-bypass scoped.

```python
# Cross-company safe
env['purchase.order'].sudo().with_company(target_company).create({...})
```

---

## 10. Studio field name collision (`x_studio_field_1` suffix)

**Symptom:** A domain that worked yesterday now fails with
`Invalid field 'x_studio_approved'`.

**Cause:** Someone deleted and recreated the Studio field. Odoo assigns a
new technical name (`x_studio_approved_1`) even though the label is identical.

Fix: always verify Technical Name via *Developer tools → View metadata* before
writing domains or automation code against a Studio field. If you control the
naming, prefer module-declared fields (no `x_` prefix) over Studio for
anything referenced by multiple automations.

---

## 11. Cron `numbercall` / `doall` in Odoo 18+

**Symptom:** Cron configured with `numbercall = -1` in XML raises
`ValueError: Invalid field`.

**Cause:** `numbercall` and `doall` were removed from `ir.cron` in 18. Interval
is the only scheduling knob.

Fix: for "run once" crons, delete the cron after it runs, or set `active = False`
inside the cron code.

---

## 12. `numbercall = 1` cron not auto-deactivating

**Symptom:** One-shot cron keeps firing.

**Cause:** Even pre-18, `numbercall = 1` only deactivates after a successful
completion. If the cron raises, the counter doesn't decrement.

Fix: wrap the cron body in try/except and set `active = False` in the
success path. In 18+, deactivate explicitly:

```python
cron = env.ref('module.ir_cron_once')
cron.sudo().write({'active': False})
```

---

## 13. Using `record` / `records` in a manual server action

**Symptom:** Manual server action works when attached to Model A but not
Model B — you end up maintaining N copies of the same action.

**Cause:** `record` and `records` are bound to the model the SA is attached
to. The *SA's* assigned model is a property of the SA config, not of what you
want to operate on.

Fix: go model-agnostic. Always resolve the data through `env[...]`:

```python
# WRONG — tied to the SA's attached model
for rec in records:
    ...

# RIGHT — works from any SA, regardless of the attached model
orders = env['sale.order'].sudo().search([...])
for rec in orders:
    ...
```

Exception: `base.automation` rules, where `records` IS the trigger record and
the attached model is meaningful — the guidance only applies to manual SAs.

---

## Quick diagnosis table

| Symptom | First thing to check |
|---|---|
| Automation doesn't fire | Trigger fields set? Domain too strict? Rule active? |
| Automation fires too often | Missing domain? Empty trigger fields on `on_write`? |
| Write disappears | `UserError` after `write()`? → use `display_notification` |
| Mail gateway broken after automation edit | Uncaught exception in `mail.message` automation? |
| Cron runs forever | Pre-18 `numbercall` logic? In 18+, delete or deactivate the cron |
| Domain suddenly breaks | Studio field was recreated and got a `_1` suffix |
