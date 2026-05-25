# ir.cron — architektúra scheduled actions

## Obsah

1. [Čo je ir.cron](#co-je-ircron)
2. [Polia modelu](#polia-modelu)
3. [Architektúra schedulera](#architektura-schedulera)
4. [Threading model](#threading-model)
5. [Error handling a auto-deaktivácia](#error-handling)
6. [Konfigurácia cez UI vs XML](#konfiguracia)
7. [Patterny](#patterny)
8. [Rozdiely medzi verziami](#rozdiely-medzi-verziami)

---

## Čo je ir.cron

`ir.cron` je Odoo model pre scheduled (časované) akcie. Na rozdiel od automated actions
(base.automation), cron joby sa nespúšťajú na základe record eventov, ale na základe ČASU.

Každý cron job volá Python metódu na špecifickom modeli v pravidelných intervaloch.

**Kedy použiť cron vs automated action:**

| Scenár | Cron | Automated Action |
|---|---|---|
| Reaguj na zmenu záznamu | Nie | Áno |
| Periodický cleanup/sync | Áno | Nie |
| Batch processing | Áno | Podmienečne (on_time) |
| External API polling | Áno | Nie (okrem webhook v17+) |
| Reminder pred deadline | Oboje | Oboje (on_time trigger) |

---

## Polia modelu

### Aktuálne (v18+)

| Pole | Typ | Default | Popis |
|---|---|---|---|
| name | Char | required | Identifikátor pre logy |
| model_id | Many2one (ir.model) | required | Model s metódou |
| method_name | Char | required | Metóda na zavolanie (bez argumentov) |
| args | Text | `()` | JSON argumenty (zriedka používané) |
| interval_number | Integer | 1 | Frekvencia — číslo |
| interval_type | Selection | 'months' | 'minutes', 'hours', 'days', 'weeks', 'months' |
| nextcall | Datetime | required | Ďalšie spustenie (UTC!) |
| lastcall | Datetime | auto | Posledné spustenie |
| active | Boolean | True | Enabled/disabled |
| priority | Integer | 5 | Priorita (nižšie = skôr) |
| user_id | Many2one (res.users) | current | User context pre execution |

### Odstránené v18+ (boli v v8-v17)

| Pole | Typ | Popis | Náhrada |
|---|---|---|---|
| numbercall | Integer | Limit spustení (-1=unlimited) | Logika v metóde |
| doall | Boolean | Spustiť vynechané behy pri recovery | Odstránené, scheduler zjednodušený |

---

## Architektúra schedulera

### Ako funguje Odoo scheduler

```
[Odoo server štart]
    ↓
[Scheduler thread(s) sa spustia]
    ↓
[Loop: každých ~60 sekúnd]
    ↓
[SELECT FROM ir_cron WHERE active=True AND nextcall <= NOW() ORDER BY priority, id]
    ↓
[Pre každý found cron job:]
    1. Acquire database lock (SELECT ... FOR UPDATE SKIP LOCKED)
    2. Execute method_name na model_id s args
    3. Update nextcall = nextcall + interval
    4. Update lastcall = NOW()
    5. Release lock
    ↓
[Sleep ~60s, repeat]
```

### Výpočet nextcall

```
nextcall = lastcall + (interval_number * interval_type)

Príklad:
  interval_number = 2
  interval_type = 'hours'
  lastcall = 2025-01-01 10:00:00
  → nextcall = 2025-01-01 12:00:00
```

**Dôležité**: `nextcall` je v UTC! Ak nastavíš cez UI, Odoo konvertuje z user timezone.

### Minimálny interval

Technicky je minimum 1 minúta, ale:
- Pod 5 minút: nestabilné na SaaS, scheduler polling je ~60s
- Odporúčané minimum: 5 minút
- Pre real-time reakcie: použi automated action, nie cron

---

## Threading model

### Konfigurácia

```ini
# odoo.conf
max_cron_threads = 2  # Default: 2 (0 = disabled)
```

- Každý cron thread je persistent počas behu jobu
- Threads sú poolované — po skončení jobu sa vrátia do poolu
- Na SaaS: kontroluje Odoo, nedá sa meniť

### Súbežné spúšťanie

- Jeden cron job = jeden thread
- Viaceré joby sa môžu bežať paralelne (do limitu max_cron_threads)
- Rovnaký cron job sa NEMÔŽE bežať paralelne — `SELECT FOR UPDATE SKIP LOCKED`
- Ak job beží dlho → blokuje svojho ďalšieho spustenia

### Multi-worker režim

```ini
# odoo.conf
workers = 4
max_cron_threads = 2
```

V multi-worker: cron thread-y bežia v JEDNOM z worker procesov (nie vo všetkých).
Ak workers > 0, Odoo vyberie jedného workera pre cron.

---

## Error handling

### Sledovanie zlyhaní

Odoo sleduje zlyhania cron jobov:

1. **3 po sebe idúce chyby** → skip aktuálnu execution (try later)
2. **5+ chýb za 7 dní** → AUTO-DEAKTIVÁCIA (`active = False`)

### Timeout

- Default timeout: závisí od konfigurácie servera (`limit_time_real`)
- Na SaaS: typicky 30-60 sekúnd
- Timeout = chyba → počíta sa do failure tracking

### Logovanie chýb

```python
# V cron metóde — VŽDY loguj
import logging
_logger = logging.getLogger(__name__)

def _cron_my_job(self):
    try:
        # business logic
        _logger.info('Cron job completed: processed %s records', count)
    except Exception as e:
        _logger.error('Cron job failed: %s', str(e))
        raise  # Re-raise aby scheduler vedel o chybe
```

### Monitorovanie

- `Settings → Technical → Scheduled Actions` → vidíš nextcall, lastcall
- Server logy: hľadaj `ir.cron` entries
- Na SaaS: `Settings → Technical → Automation → Scheduled Actions`

---

## Konfigurácia cez UI vs XML

### Cez UI (Studio/Settings)

1. `Settings → Technical → Automation → Scheduled Actions`
2. Klikni "New"
3. Vyplň:
   - Name
   - Model (musí mať metódu)
   - Method: názov metódy
   - Interval: číslo + typ
   - Next Execution: kedy prvýkrát

### Cez XML (v module)

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

### Cez server action (SaaS workaround)

Na SaaS nemôžeš vytvárať cron cez XML. Alternatíva:
1. Vytvor Server Action s Python kódom
2. Vytvor Scheduled Action v UI
3. Nastav metódu: `model.action_server_run()`
4. Alebo použi Automated Action s on_time triggerom

---

## Patterny

### Jednoduchý cleanup

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

### Batch processing s progressom

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
        
        # Commit po batchi (len v cron/module kontexte!)
        self.env.cr.commit()
    
    _logger.info('Synced %s/%s records', processed, total)
```

### Idempotentný (bezpečný na opakované spustenie)

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
            # Pokračuj s ďalšími — nefailni celý batch kvôli jednému
```

### Run-once (náhrada za numbercall)

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

## Rozdiely medzi verziami

### v8-v17: numbercall + doall

```xml
<!-- Starý štýl -->
<record model="ir.cron" id="cron_old_style">
    <field name="numbercall">10</field>  <!-- Run 10x then stop -->
    <field name="doall" eval="True"/>    <!-- Execute missed runs -->
</record>
```

### v18+: iba interval

```xml
<!-- Nový štýl — len interval -->
<record model="ir.cron" id="cron_new_style">
    <field name="interval_number">1</field>
    <field name="interval_type">days</field>
    <!-- numbercall a doall neexistujú -->
</record>
```

### Migrácia numbercall → v18+

Ak si používal `numbercall` na run-once joby:
1. Použi ICP flag (viď Run-Once pattern vyššie)
2. Alebo self-deactivate: `cron.write({'active': False})` na konci

Ak si používal `doall` na catch-up po výpadku:
1. V metóde spracuj všetky záznamy kde `nextcall` bol preskočený
2. Použi `lastcall` z cron recordu na určenie čo bolo vynechané
