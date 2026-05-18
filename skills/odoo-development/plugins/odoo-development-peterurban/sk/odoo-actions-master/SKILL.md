---
name: odoo-actions-master
description: Encyklopédia Odoo action systému — Automated Actions, Server Actions, Studio automatizácia, cron, action dispatch architektúra, a kompletná mapa modelových vzťahov (v8→19). Triggeruj pri automated actions, server actions, cron/scheduled actions, base.automation, ir.actions, Studio automatizácia, action chaining, webhooky, rozdiely Odoo verzií pre akcie, vzťahy modelov, FK prepojenia (sale.order→stock.picking→account.move), field typy, x2many commands, domain syntax, alebo "ktoré pole spája X s Y". Doplňuje odoo-server-actions (safe_eval detaily) architektúrou, patternami, version history, a cross-module model/field referenciou.
---

# Odoo Actions Master — Architektúra, automatizácia a patterny (v8→v19)

Tento skill je encyklopédia Odoo action systému. Pokrýva architektúru, všetky typy akcií,
automated actions, server actions, cron, Studio automatizáciu, a komplexné patterny naprieč
všetkými verziami Odoo.

**Pre safe_eval sandbox detaily** (forbidden builtins, dunder restrictions, workaroundy):
→ Čítaj `odoo-server-actions` skill. Tento skill sa zameriava na architektúru a patterny,
nie na safe_eval syntax.

---

## Routing — Kde hľadať čo

| Potrebuješ vedieť... | Čítaj reference |
|---|---|
| DB schéma, action typy, dispatch flow, ORM context, security | `references/architecture.md` |
| base.automation — triggery, filtrovanie, execution, Studio UI | `references/automated-actions.md` |
| Komplexné Python patterny, chaining, webhooky | `references/complex-patterns.md` |
| **Anti-patterns & gotchas** (infinite loops, O2M trap, UserError rollback, mail.message, Studio field collisions, cron quirks) | **`references/anti-patterns.md`** |
| Zmeny medzi verziami (v8→v19), breaking changes | `references/version-history.md` |
| ir.cron — scheduling, threading, error handling | `references/cron-system.md` |
| **Modely, FK prepojenia, cross-module diagram (SO→picking→invoice)** | **`references/model-map.md`** |
| **Field typy, atribúty, x2many commands, domain syntax, naming** | **`references/fields-and-domains.md`** |

---

## Quick Reference — Typy akcií

Odoo má 5 hlavných typov akcií. Všetky dedia z `ir.actions.actions` (base table `ir_actions`):

### ir.actions.act_window
Najčastejší typ. Otvorí view (form, tree, kanban...) pre daný model.
- Kľúčové polia: `res_model`, `view_mode`, `domain`, `context`, `target`
- Target: `current` (hlavná oblasť), `new` (dialóg), `fullscreen`

### ir.actions.server
Backend Python akcia. Toto je jadro automatizácie.
- States: `code`, `object_create`, `object_write`, `multi`, `email`, `followers`, `sms`, `webhook`
- Execution context: `env`, `model`, `record`/`records`, `datetime`, `time`, `UserError`, `log()`
- Binding: `binding_model_id` + `binding_type` = objaví sa v Action/Print menu

### ir.actions.report
Generuje PDF/HTML report cez QWeb template.
- Kľúčové: `report_name` (template XML ID), `report_type` (qweb-pdf/qweb-html)

### ir.actions.act_url
Otvorí URL v browseri. Jednoduché.
- `target`: `self` (rovnaký tab), `new` (nový tab), `download`

### ir.actions.client
Client-side JavaScript/OWL akcia.
- `tag`: identifikátor registrovaný v JS action registry
- Príklad: POS UI, dashboard widgety, `display_notification`

---

## Quick Reference — Triggery automated actions

| Trigger | Kedy sa spustí | Trigger fields? | Poznámka |
|---|---|---|---|
| `on_create` | Nový record uložený | Nie | Raz pri vytvorení |
| `on_write` | Existujúci record uložený | Áno (povinné) | Iba ak sa zmenili sledované polia |
| `on_create_or_write` | Create alebo write | Áno (pre write) | Kombinácia |
| `on_unlink` | Record zmazaný | Nie | Po delete |
| `on_change` / `on_form_change` | Pole sa zmení na forme (pred uložením) | Áno (povinné) | Iba UI, iba s Execute Code |
| `on_time` | Dátumové pole + delay | Nie | Scheduler kontroluje periodicky |

---

## Quick Reference — Kedy čo použiť

| Scenár | Riešenie |
|---|---|
| Reagovať na zmenu stavu záznamu | Automated Action, trigger `on_write`, trigger field = `state` |
| Tlačidlo na forme | Server Action s `binding_model_id` alebo priamy `<button>` v XML |
| Hromadná akcia z listu | Server Action s binding type `action` |
| Periodická úloha (cleanup, sync) | `ir.cron` (scheduled action) |
| Reakcia na externý systém | Webhook trigger (v17+) alebo cron polling |
| Validácia pred uložením | `on_change` trigger (iba UI) alebo `@api.constrains` v module |
| Kaskádová zmena (parent→child) | Automated Action na child modeli, nie parent |
| Read-only diagnostika | Server Action s `raise UserError(...)` |
| Write + potvrdenie | Server Action s `display_notification` |

---

## Architektúra v skratke

### Action dispatch flow (frontend → backend)

1. Užívateľ klikne button/menu → frontend pošle RPC request
2. Backend metóda vráti action dict `{'type': 'ir.actions.X', ...}`
3. Frontend dispatchuje podľa `type`:
   - `act_window` → renderuje views cez ORM
   - `server` → spustí Python kód server-side
   - `report` → generuje PDF/HTML
   - `act_url` → naviguje browser
   - `client` → spustí JavaScript handler

### Execution pipeline automated actions

1. ORM operácia (create/write/unlink) na sledovanom modeli
2. `base.automation` pravidlá sa matchnú podľa modelu a triggeru
3. `filter_pre_domain` (stav PRED operáciou) sa vyhodnotí
4. `filter_domain` (stav PO operácii) sa vyhodnotí
5. Ak obe podmienky prejdú → akcia sa spustí s `sudo()`
6. Pre `on_time`: scheduler beží periodicky, kontroluje `trg_date_id + delay <= now()`

### Security pre akcie

- **ACLs** (`ir.model.access`): Model-level CRUD permissions. Aditívne (OR medzi groups).
- **Record Rules** (`ir.rule`): Record-level domain filter.
  - Global rules (bez groups): ALL musia prejsť (AND). Restriktívne.
  - Group rules: ANY môže prejsť (OR). Permisívne.
- **Automated actions** bežia s `sudo()` — obchádzajú ACLs aj record rules.
- **Server actions** manuálne spustené rešpektujú user permissions.
- `groups_id` na server action = kto môže akciu spustiť.

---

## Dôležité gotchas (bez safe_eval — tie sú v odoo-server-actions)

1. **O2M triggery**: Automated Action na parent modeli NEIGNORUJE zmeny v O2M riadkoch. Trigger daj na child model a write() stav na parent.

2. **Cascading automations**: Automated action A zmení field → triggeruje action B → triggeruje action C. Žiadna built-in ochrana proti infinite loops. Použi guard: `if self.env.context.get('skip_automation'): return`

3. **on_change len UI**: Trigger `on_change`/`on_form_change` sa spustí LEN pri zmene na forme v UI. API/import/cron ho nespustí.

4. **Webhook payload**: Od v17. POST request na Odoo URL. Payload je JSON s field values záznamu.

5. **Cron failures**: 3 po sebe idúce chyby → skip. 5+ chýb za 7 dní → auto-deaktivácia.

6. **numbercall/doall removed (v18+)**: `ir.cron` v Odoo 18+ nemá `numbercall` a `doall`. Interval-only scheduling.

7. **Studio field suffix**: Zmazanie a znovuvytvorenie Studio poľa → `x_studio_field_1`. Vždy over Technical Name pred použitím v doméne/akcii.

---

## Workflow: Ako navrhnúť automatizáciu

1. **Identifikuj trigger event** — Čo spúšťa akciu? (zmena stavu, vytvorenie záznamu, čas, externý systém)
2. **Vyber mechanizmus**:
   - Jednoduchý field update → Automated Action, typ "Update Record"
   - Komplexná logika → Automated Action, typ "Execute Python Code"
   - Manuálne spustenie → Server Action s binding
   - Periodické → ir.cron
   - Externé → Webhook (v17+) alebo cron polling
3. **Navrhni podmienky** — `filter_pre_domain` (pred) + `filter_domain` (po) pre state transitions
4. **Vyber output metódu**:
   - Read-only → `raise UserError(...)`
   - Write + UI feedback → `display_notification`
   - Write + ticho → žiadny return
5. **Testuj** — Na nekritických záznamoch. Sleduj Network tab pre reálne chyby.
6. **Dokumentuj** — Notes tab na automated action. Čo robí, prečo, kto vlastní.

---

---

## Quick Reference — modely a polia

Skill obsahuje kompletný model relationship map v `references/model-map.md`. Tu sú najdôležitejšie
cross-module prepojenia:

| Z modelu | Pole | Typ | Na model | Popis |
|---|---|---|---|---|
| sale.order | picking_ids | O2M | stock.picking | Dodávky |
| sale.order | invoice_ids | M2M | account.move | Faktúry |
| sale.order.line | invoice_lines | M2M | account.move.line | Fakturačné riadky |
| stock.picking | sale_id | M2O | sale.order | Zdrojová SO |
| stock.picking | purchase_id | M2O | purchase.order | Zdrojová PO |
| stock.move | sale_line_id | M2O | sale.order.line | Reverse trace na SO |
| stock.move | purchase_line_id | M2O | purchase.order.line | Reverse trace na PO |
| stock.move | raw_material_production_id | M2O | mrp.production | Spotreba MO |
| project.task | sale_line_id | M2O | sale.order.line | Riadok Service SO |
| account.move.line | sale_line_ids | M2M | sale.order.line | Riadky SO |
| account.move.line | purchase_line_id | M2O | purchase.order.line | Riadok PO |
| hr.employee | user_id | M2O | res.users | Systémový účet |
| res.users | partner_id | M2O | res.partner | Delegation inheritance |

Pre kompletný diagram so všetkými poľami → čítaj `references/model-map.md`.
Pre field types, attributes, x2many commands, domains → čítaj `references/fields-and-domains.md`.

---

## Kedy čítať reference súbory

- Píšeš alebo debuguješ automated action → `references/automated-actions.md`
- Potrebuješ pochopiť ako action systém funguje → `references/architecture.md`
- Píšeš komplexný Python pattern (chaining, multi-step, webhook) → `references/complex-patterns.md`
- Niečo sa nechová ako má / objavil si nezvyčajný symptom → `references/anti-patterns.md`
- Zaujíma ťa čo sa zmenilo medzi verziami → `references/version-history.md`
- Robíš s cron jobmi → `references/cron-system.md`
- Hľadáš technický názov poľa, FK prepojenie, alebo cross-module flow → `references/model-map.md`
- Potrebuješ field type, attribute, x2many command, domain syntax → `references/fields-and-domains.md`
- Safe_eval sandbox (builtins, dunders, workaroundy) → **čítaj skill `odoo-server-actions`**
