---
name: odoo-actions-master
description: Odoo action system encyclopedia — Automated Actions, Server Actions, Studio automation, cron, action dispatch architecture, and full model relationship map (v8→19). Trigger on automated actions, server actions, cron/scheduled actions, base.automation, ir.actions, Studio automation, action chaining, webhooks, Odoo version differences for actions, model relationships, FK connections (sale.order→stock.picking→account.move), field types, x2many commands, domain syntax, or "which field connects X to Y". Complements odoo-server-actions (safe_eval details) with architecture, patterns, version history, and cross-module model/field reference.
---

# Odoo Actions Master — Architecture, Automation & Patterns (v8→v19)

This skill is an encyclopedia of the Odoo action system. It covers the architecture, all action types,
automated actions, server actions, cron, Studio automation, and complex patterns across all Odoo
versions.

**For safe_eval sandbox details** (forbidden builtins, dunder restrictions, workarounds):
→ See the `odoo-server-actions` skill. This skill focuses on architecture and patterns,
not on safe_eval syntax.

---

## Routing — Where to look for what

| If you need to know... | Read reference |
|---|---|
| DB schema, action types, dispatch flow, ORM context, security | `references/architecture.md` |
| base.automation — triggers, filtering, execution, Studio UI | `references/automated-actions.md` |
| Complex Python patterns, chaining, webhooks | `references/complex-patterns.md` |
| **Anti-patterns & gotchas** (infinite loops, O2M trap, UserError rollback, mail.message, Studio field collisions, cron quirks) | **`references/anti-patterns.md`** |
| Changes between versions (v8→v19), breaking changes | `references/version-history.md` |
| ir.cron — scheduling, threading, error handling | `references/cron-system.md` |
| **Models, FK connections, cross-module diagram (SO→picking→invoice)** | **`references/model-map.md`** |
| **Field types, attributes, x2many commands, domain syntax, naming** | **`references/fields-and-domains.md`** |

---

## Quick Reference — Action Types

Odoo has 5 main action types. All inherit from `ir.actions.actions` (base table `ir_actions`):

### ir.actions.act_window
The most common type. Opens a view (form, tree, kanban...) for a given model.
- Key fields: `res_model`, `view_mode`, `domain`, `context`, `target`
- Target: `current` (main area), `new` (dialog), `fullscreen`

### ir.actions.server
Backend Python action. This is the core of automation.
- States: `code`, `object_create`, `object_write`, `multi`, `email`, `followers`, `sms`, `webhook`
- Execution context: `env`, `model`, `record`/`records`, `datetime`, `time`, `UserError`, `log()`
- Binding: `binding_model_id` + `binding_type` = appears in the Action/Print menu

### ir.actions.report
Generates a PDF/HTML report via a QWeb template.
- Key fields: `report_name` (template XML ID), `report_type` (qweb-pdf/qweb-html)

### ir.actions.act_url
Opens a URL in the browser. Simple.
- `target`: `self` (same tab), `new` (new tab), `download`

### ir.actions.client
Client-side JavaScript/OWL action.
- `tag`: identifier registered in the JS action registry
- Example: POS UI, dashboard widgets, `display_notification`

---

## Quick Reference — Automated Action Triggers

| Trigger | When it fires | Trigger fields? | Note |
|---|---|---|---|
| `on_create` | New record saved | No | Once on creation |
| `on_write` | Existing record saved | Yes (required) | Only if tracked fields changed |
| `on_create_or_write` | Create or write | Yes (for write) | Combination |
| `on_unlink` | Record deleted | No | After delete |
| `on_change` / `on_form_change` | Field changes on the form (before save) | Yes (required) | UI only, only with Execute Code |
| `on_time` | Date field + delay | No | Scheduler checks periodically |

---

## Quick Reference — When to use what

| Scenario | Solution |
|---|---|
| React to a record state change | Automated Action, trigger `on_write`, trigger field = `state` |
| Button on a form | Server Action with `binding_model_id` or a direct `<button>` in XML |
| Bulk action from a list | Server Action with binding type `action` |
| Periodic task (cleanup, sync) | `ir.cron` (scheduled action) |
| Reaction to an external system | Webhook trigger (v17+) or cron polling |
| Validation before save | `on_change` trigger (UI only) or `@api.constrains` in a module |
| Cascading change (parent→child) | Automated Action on the child model, not the parent |
| Read-only diagnostics | Server Action with `raise UserError(...)` |
| Write + confirmation | Server Action with `display_notification` |

---

## Architecture in brief

### Action Dispatch Flow (frontend → backend)

1. User clicks a button/menu → frontend sends an RPC request
2. Backend method returns an action dict `{'type': 'ir.actions.X', ...}`
3. Frontend dispatches based on `type`:
   - `act_window` → renders views via the ORM
   - `server` → runs Python code server-side
   - `report` → generates PDF/HTML
   - `act_url` → navigates the browser
   - `client` → runs a JavaScript handler

### Automated Action Execution Pipeline

1. ORM operation (create/write/unlink) on the tracked model
2. `base.automation` rules are matched by model and trigger
3. `filter_pre_domain` (state BEFORE the operation) is evaluated
4. `filter_domain` (state AFTER the operation) is evaluated
5. If both conditions pass → the action runs with `sudo()`
6. For `on_time`: the scheduler runs periodically and checks `trg_date_id + delay <= now()`

### Security for actions

- **ACLs** (`ir.model.access`): Model-level CRUD permissions. Additive (OR across groups).
- **Record Rules** (`ir.rule`): Record-level domain filter.
  - Global rules (no groups): ALL must pass (AND). Restrictive.
  - Group rules: ANY may pass (OR). Permissive.
- **Automated actions** run with `sudo()` — they bypass ACLs and record rules.
- **Server actions** triggered manually respect user permissions.
- `groups_id` on a server action = who can run the action.

---

## Important gotchas (excluding safe_eval — those are in odoo-server-actions)

1. **O2M triggers**: An Automated Action on the parent model DOES NOT detect changes in O2M lines. Put the trigger on the child model and write() the state onto the parent.

2. **Cascading automations**: Automated action A changes a field → triggers action B → triggers action C. There is no built-in protection against infinite loops. Use a guard: `if self.env.context.get('skip_automation'): return`

3. **on_change is UI-only**: The `on_change`/`on_form_change` trigger fires ONLY when a field is changed on a form in the UI. API/import/cron will not fire it.

4. **Webhook payload**: Since v17. POST request to an Odoo URL. Payload is JSON with the record's field values.

5. **Cron failures**: 3 consecutive errors → skip. 5+ errors in 7 days → auto-deactivation.

6. **numbercall/doall removed (v18+)**: `ir.cron` in Odoo 18+ does not have `numbercall` or `doall`. Interval-only scheduling.

7. **Studio field suffix**: Deleting and recreating a Studio field → `x_studio_field_1`. Always verify the Technical Name before using it in a domain/action.

---

## Workflow: How to design an automation

1. **Identify the trigger event** — What triggers the action? (state change, record creation, time, external system)
2. **Choose the mechanism**:
   - Simple field update → Automated Action, type "Update Record"
   - Complex logic → Automated Action, type "Execute Python Code"
   - Manual trigger → Server Action with binding
   - Periodic → ir.cron
   - External → Webhook (v17+) or cron polling
3. **Design the conditions** — `filter_pre_domain` (before) + `filter_domain` (after) for state transitions
4. **Choose the output method**:
   - Read-only → `raise UserError(...)`
   - Write + UI feedback → `display_notification`
   - Write + silent → no return
5. **Test** — On non-critical records. Watch the Network tab for real errors.
6. **Document** — Notes tab on the automated action. What it does, why, who owns it.

---

---

## Model & Field Quick Reference

The skill contains a complete model relationship map in `references/model-map.md`. Here are the most important
cross-module connections:

| From model | Field | Type | To model | Description |
|---|---|---|---|---|
| sale.order | picking_ids | O2M | stock.picking | Deliveries |
| sale.order | invoice_ids | M2M | account.move | Invoices |
| sale.order.line | invoice_lines | M2M | account.move.line | Invoice lines |
| stock.picking | sale_id | M2O | sale.order | Source SO |
| stock.picking | purchase_id | M2O | purchase.order | Source PO |
| stock.move | sale_line_id | M2O | sale.order.line | Reverse trace to SO |
| stock.move | purchase_line_id | M2O | purchase.order.line | Reverse trace to PO |
| stock.move | raw_material_production_id | M2O | mrp.production | MO consumption |
| project.task | sale_line_id | M2O | sale.order.line | Service SO line |
| account.move.line | sale_line_ids | M2M | sale.order.line | SO lines |
| account.move.line | purchase_line_id | M2O | purchase.order.line | PO line |
| hr.employee | user_id | M2O | res.users | System account |
| res.users | partner_id | M2O | res.partner | Delegation inheritance |

For the full diagram with all fields → see `references/model-map.md`.
For field types, attributes, x2many commands, domains → see `references/fields-and-domains.md`.

---

## When to read the reference files

- Writing or debugging an automated action → `references/automated-actions.md`
- Need to understand how the action system works → `references/architecture.md`
- Writing a complex Python pattern (chaining, multi-step, webhook) → `references/complex-patterns.md`
- Something is not behaving as expected / unusual symptom → `references/anti-patterns.md`
- Interested in what changed between versions → `references/version-history.md`
- Working with cron jobs → `references/cron-system.md`
- Looking for a field's technical name, FK connection, or cross-module flow → `references/model-map.md`
- Need a field type, attribute, x2many command, domain syntax → `references/fields-and-domains.md`
- Safe_eval sandbox (builtins, dunders, workarounds) → **see skill `odoo-server-actions`**
