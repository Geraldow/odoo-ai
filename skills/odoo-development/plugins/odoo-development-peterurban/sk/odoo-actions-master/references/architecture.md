# Odoo action architektúra — DB schéma, dispatch, ORM, security

## Obsah

1. [Databázová schéma](#databazova-schema)
2. [Action dispatch pipeline](#action-dispatch-pipeline)
3. [ORM execution context](#orm-execution-context)
4. [Security vrstva](#security-vrstva)
5. [Model inheritance](#model-inheritance)

---

## Databázová schéma

### Hlavné tabuľky

Všetky action typy dedia z jednej base tabuľky `ir_actions`:

```
ir_actions (base)
├── ir_act_window        → Window actions (views)
├── ir_act_server         → Server actions (Python code)
├── ir_act_report_xml     → Report actions (PDF/HTML)
├── ir_act_url            → URL actions
├── ir_actions_todo       → Configuration wizards
└── ir_cron               → Scheduled actions (cron)
```

### ir_actions (base tabuľka)

| Stĺpec | Typ | Popis |
|---|---|---|
| id | serial | PK |
| name | varchar | Názov akcie |
| type | varchar | Discriminator: 'ir.actions.act_window', 'ir.actions.server', atď. |
| help | text | Help text (voliteľný) |
| binding_model_id | int (FK) | Model kde sa action objaví v menu |
| binding_type | varchar | 'action', 'report' |
| binding_view_types | varchar | 'list,form' — kde sa zobrazí |

### ir_act_window

| Stĺpec | Typ | Popis |
|---|---|---|
| res_model | varchar | Cieľový model (napr. 'sale.order') |
| view_mode | varchar | Comma-separated: 'tree,form,kanban,pivot,graph' |
| view_id | int (FK) | Default view |
| search_view_id | int (FK) | Search view |
| domain | text | Filtrovací domain (JSON string) |
| context | text | Context dict (JSON string) |
| target | varchar | 'current', 'new', 'fullscreen', 'main' |
| limit | int | Default page limit |
| groups_id | M2M | Kto vidí akciu |

### ir_act_server

| Stĺpec | Typ | Popis |
|---|---|---|
| model_id | int (FK → ir_model) | Base model akcie |
| state | varchar | 'code', 'object_create', 'object_write', 'multi', 'email', 'followers', 'sms', 'webhook' |
| code | text | Python kód (pre state='code') |
| child_ids | M2M | Sub-akcie (pre state='multi') |
| groups_id | M2M (→ res_groups) | Kto môže spustiť |
| condition | text | Python podmienka (default='True') |
| fields_lines | O2M (→ ir.server.object.lines) | Field-value mappings pre create/write |

Junction table pre child_ids: `rel_server_actions` (server_id, action_id)

### base_automation

| Stĺpec | Typ | Popis |
|---|---|---|
| name | varchar | Názov pravidla |
| model_id | int (FK → ir_model) | Sledovaný model |
| active | bool | Enabled/disabled |
| trigger | varchar | 'on_create', 'on_write', 'on_create_or_write', 'on_unlink', 'on_change', 'on_time' |
| state | varchar | Typ akcie ('code', 'actions') |
| code | text | Python kód |
| action_server_ids | M2M | Server actions na spustenie |
| filter_domain | text | Domain po operácii |
| filter_pre_domain | text | Domain pred operáciou |
| trigger_field_ids | M2M (→ ir.model.fields) | Sledované polia |
| trg_date_id | int (FK → ir.model.fields) | Dátumové pole pre on_time |
| trg_date_range | int | Delay hodnota |
| trg_date_range_type | varchar | 'minutes', 'hours', 'days', 'months' |

### ir_cron

| Stĺpec | Typ | Popis |
|---|---|---|
| name | varchar | Identifikátor |
| model_id | int (FK) | Model s metódou |
| method_name | varchar | Názov metódy na zavolanie |
| args | text | JSON argumenty |
| interval_number | int | Frekvencia (default=1) |
| interval_type | varchar | 'minutes', 'hours', 'days', 'weeks', 'months' |
| nextcall | timestamp | Ďalšie spustenie (UTC) |
| lastcall | timestamp | Posledné spustenie |
| numbercall | int | Limit spustení (-1=unlimited) [ODSTRÁNENÉ v18+] |
| doall | bool | Spustiť vynechané behy [ODSTRÁNENÉ v18+] |
| active | bool | Enabled/disabled |

---

## Action dispatch pipeline

### Frontend → backend → frontend

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

### Execution server action (ir.actions.server.run())

1. `_get_eval_context()` — zostaví globals dict pre safe_eval
2. `condition` sa vyhodnotí — ak False, skip
3. Podľa `state`:
   - `code` → `safe_eval(self.code, eval_context, mode='exec')`
   - `multi` → iteruje `child_ids`, každý `.run()`, vráti posledný result
   - `object_create` → vytvorí record podľa `fields_lines`
   - `object_write` → updatne record podľa `fields_lines`
   - `email/sms/followers` → deleguje na príslušný mixin
4. Ak kód vracia action dict → frontend ho dispatchuje ďalej

### Pipeline automated action (base.automation._process())

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

### Návratové hodnoty

Server action kód môže vrátiť:
- `None` — nič sa nestane
- Action dict — frontend ho spustí (otvorí view, stiahne report, atď.)
- Priradiť do premennej `action` — implicitne sa vráti

```python
# Explicit return (v15+)
action = {'type': 'ir.actions.act_window', 'res_model': 'sale.order', ...}

# display_notification (write-safe — žiadny rollback)
action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {'title': 'OK', 'message': 'Done', 'type': 'success', 'sticky': False}
}
```

---

## ORM execution context

### Environment (env)

```python
env.cr        # Database cursor (transaction)
env.uid       # Current user ID (int)
env.user      # Current user record (res.users)
env.context   # Dict s kontextom (lang, tz, active_id, ...)
env.company   # Current company (res.company)
env.companies # All allowed companies
```

### Operácie s recordsetom

```python
# CRUD
record = model.create({'name': 'Test'})
records = model.search([('state', '=', 'draft')], limit=10, order='id desc')
records = model.browse([1, 2, 3])
records.write({'state': 'confirmed'})
records.unlink()

# Set operations
union = rs1 | rs2         # Zjednotenie
intersection = rs1 & rs2  # Prienik
difference = rs1 - rs2    # Rozdiel
is_in = record in records # Členstvo

# Iteration
for rec in records:
    print(rec.name)

# Mapping / Filtering
names = records.mapped('name')                        # [str, str, ...]
partners = records.mapped('partner_id')               # recordset
expensive = records.filtered(lambda r: r.amount > 1000)
total = records.mapped(lambda r: r.qty * r.price)     # [float, float, ...]
```

### Manipulácia s contextom

```python
# Merge (zachová existujúci context + pridá)
record.with_context(key='value')

# Replace (nahradí celý context)
record.with_context({}, new_key='value')

# Bežné použitia
record.with_context(tracking_disable=True).write(vals)  # Bez mail tracking
record.with_context(lang='sk_SK').name_get()             # Slovenský preklad
record.with_context(force_company=company_id).create(vals)
```

### sudo() a with_user()

```python
# Superuser — obíde ACLs aj record rules
admin_records = records.sudo()

# Konkrétny user
user_records = records.with_user(user_id)

# sudo() NEZMENÍ env.uid pre logging — len obíde security checks
# Pozor: sudo() je "sticky" — raz zavolaný, všetky operácie na výsledku sú sudo
```

### Priame SQL

```python
# Read-only diagnostika
env.cr.execute("SELECT id, name FROM sale_order WHERE state = 'draft' LIMIT 5")
rows = env.cr.fetchall()  # [(1, 'SO001'), (2, 'SO002'), ...]

# Dictfetch
env.cr.execute("SELECT id, name FROM sale_order LIMIT 5")
rows = env.cr.dictfetchall()  # [{'id': 1, 'name': 'SO001'}, ...]

# POZOR: Po raw SQL vždy invalidate cache
env.invalidate_all()
```

---

## Security vrstva

### ACL (ir.model.access)

Model-level CRUD permissions. Definované v `security/ir.model.access.csv`:

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_sale_user,sale.order.user,model_sale_order,sales_team.group_sale_salesman,1,1,1,0
access_sale_manager,sale.order.manager,model_sale_order,sales_team.group_sale_manager,1,1,1,1
```

Pravidlá:
- **Aditívne** (OR): ak AKÁKOĽVEK group dáva permission, user ju má
- **Default-deny**: ak neexistuje žiadne ACL pre model, len superuser (uid=1) má prístup
- Prázdne `group_id` = platí pre VŠETKÝCH users

### Record rules (ir.rule)

Record-level filtering. Dva typy:

**Global rules** (žiadne groups):
- AND medzi sebou — VŠETKY musia prejsť
- Restriktívne — zužujú prístup

**Group rules** (s groups):
- OR medzi sebou — AKÉKOĽVEK z nich stačí
- Permisívne — rozširujú prístup

**Kombinované**: (VŠETKY global) AND (AKÁKOĽVEK group alebo žiadna ak user nemá žiadnu relevantnú group)

```xml
<!-- Vidí len záznamy svojej company -->
<record model="ir.rule" id="rule_sale_company">
    <field name="name">Sale Order: company</field>
    <field name="model_id" ref="model_sale_order"/>
    <field name="domain_force">[('company_id', 'in', company_ids)]</field>
    <field name="perm_read" eval="True"/>
</record>
```

Domain premenné v record rules: `user`, `company_ids`, `company_id`, `time`

### Security v kontexte akcií

| Kontext | Security |
|---|---|
| Automated action (base.automation) | Beží s `sudo()` — obchádza ACLs aj rules |
| Server action — manuálne spustené | Rešpektuje user permissions |
| Server action — cez automated action | Dedí `sudo()` z automated action |
| Cron job (ir.cron) | Beží ako superuser (uid=1) |
| Python kód s `sudo()` | Obchádza security, ale NIE SQL constraints |

---

## Model inheritance

### Classical (_inherit)

Rozširuje existujúci model. Rovnaká DB tabuľka.

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

Nová tabuľka, transparentný prístup k parent poliam.

```python
class Student(models.Model):
    _name = 'school.student'
    _inherits = {'res.partner': 'partner_id'}
    partner_id = fields.Many2one('res.partner', required=True, ondelete='cascade')
    grade = fields.Char()
    # student.name → transparentne číta z res.partner
```

### Abstraktný (_inherit bez _name)

Mixin bez vlastnej tabuľky.

```python
class MailThread(models.AbstractModel):
    _name = 'mail.thread'
    # Zdieľa metódy a fields, ale nemá vlastnú tabuľku
```

### Praktický dopad na akcie

- Classical inheritance: Automated action na `sale.order` zachytí aj custom fields z rozšírení
- Delegation: Automated action na `school.student` NEVIDÍ zmeny na `res.partner` priamo — trigger treba dať na oba modely
- Studio fields (`x_studio_*`): Sú classical inheritance pod kapotou — fungujú v automated actions normálne
