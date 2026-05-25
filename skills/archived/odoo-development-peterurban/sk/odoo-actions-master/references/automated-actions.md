# Automated actions (base.automation) — Triggery, filtrovanie, execution, Studio

## Obsah

1. [Čo je base.automation](#co-je-baseautomation)
2. [Typy triggerov](#typy-triggerov)
3. [Filtrovanie domény](#filtrovanie-domeny)
4. [Typy akcií](#typy-akcii)
5. [Studio UI](#studio-ui)
6. [Studio vs Technical Menu](#studio-vs-technical-menu)
7. [Studio limity a workaroundy](#studio-limity-a-workaroundy)
8. [Best practices](#best-practices)
9. [Debugging](#debugging)

Pre footguny (infinite loops, O2M trigger trap, UserError rollback, mail.message
automatizácia, kolízie Studio field-name) pozri **[anti-patterns.md](anti-patterns.md)**.

---

## Čo je base.automation

`base.automation` je model ktorý "počúva" na ORM operáciách (create, write, unlink, form change,
time conditions) a automaticky spúšťa akcie. Pod kapotou hookuje do ORM metód modelu pri
registrácii pravidla a volá akciu keď sa podmienky splnia.

Modul: `base_automation` (musí byť nainštalovaný; v Enterprise/SaaS je defaultne)

Kľúčový rozdiel od `ir.actions.server`: Automated action sa spúšťa AUTOMATICKY na základe
eventu. Server action sa spúšťa MANUÁLNE (button, menu) alebo je volaná z automated action.

---

## Typy triggerov

### on_create

**Kedy**: Nový záznam sa vytvorí a uloží (po `create()` commite)

```
Použitie: Inicializácia, default hodnoty, notifikácie pri vytvorení
Kontext: records = novovytvorený záznam(y)
Trigger fields: Nie sú relevantné
```

Príklad: Nový sales order → automaticky priraď sales team podľa partnera.

### on_write

**Kedy**: Existujúci záznam sa uloží a sledované polia sa zmenili

```
Použitie: Reakcia na zmenu stavu, field update cascading
Kontext: records = upravený záznam(y)
Trigger fields: POVINNÉ — musíš vybrať minimálne jedno pole
```

**Dôležité**: Ak nevyberieš trigger fields, akcia sa môže spúšťať pri KAŽDOM write, čo je
performance disaster.

Príklad: `state` sa zmení na 'confirmed' → vytvor delivery order.

### on_create_or_write

**Kedy**: Kombinácia on_create + on_write

```
Použitie: Keď chceš rovnakú logiku pri create aj write
Trigger fields: Relevantné pre write časť
```

### on_unlink

**Kedy**: Záznam sa zmaže (po `unlink()`)

```
Použitie: Cleanup, audit logging, cascade operations
Kontext: records = záznamy pred zmazaním (ešte existujú v pamäti)
Poznámka: Zriedka používané — Odoo preferuje archiving nad deleting
```

### on_change / on_form_change (v17+: "On UI Change")

**Kedy**: Pole sa zmení na forme v UI, PRED uložením

```
Použitie: Real-time UI feedback, dynamické default hodnoty
Trigger fields: POVINNÉ
Obmedzenia:
  - Funguje LEN v UI (nie cez API, import, cron)
  - Funguje LEN s action type "Execute Python Code"
  - Nespustí sa ak pole zmenila INÁ automated action
  - V17+ premenované na "Based on Form Modification" / "On UI Change"
```

### on_time / based_on_time_condition

**Kedy**: Dátumové pole + delay dosiahne aktuálny čas

```
Použitie: Reminders, expirácia, auto-archiving, follow-up
Konfigurácia:
  trg_date_id = dátumové pole (napr. 'date_deadline')
  trg_date_range = číslo (napr. 3)
  trg_date_range_type = 'days' / 'hours' / 'minutes' / 'months'
Scheduler: Beží periodicky (default ~4h, pre <40h delays častejšie)
Obmedzenia: Funguje LEN s "Execute Python Code" action type
```

Záporný `trg_date_range` = pred dátumom (napr. -2 days = 2 dni pred deadline).

---

## Filtrovanie domény

Automated actions majú DVA domain filtre, čo umožňuje zachytiť STATE TRANSITIONS:

### filter_pre_domain (Before Update Domain)

Vyhodnotí sa proti STARÝM hodnotám záznamu (pred operáciou).

```python
# Príklad: Iba ak stav bol 'draft' pred zmenou
[('state', '=', 'draft')]
```

### filter_domain (After Update Domain)

Vyhodnotí sa proti NOVÝM hodnotám záznamu (po operácii).

```python
# Príklad: Iba ak stav je teraz 'confirmed'
[('state', '=', 'confirmed')]
```

### Pattern state transition

Kombinácia oboch pre zachytenie prechodu:

```
filter_pre_domain: [('state', '=', 'draft')]
filter_domain:     [('state', '=', 'confirmed')]
→ Spustí sa IBA keď stav sa zmení z 'draft' na 'confirmed'
```

Toto je najčastejší pattern a hlavný dôvod prečo existujú dva filtre.

### Gotchas domain syntaxe

```python
# AND (default) — všetky podmienky musia platiť
[('state', '=', 'draft'), ('amount', '>', 100)]

# OR — prefix operátor
['|', ('state', '=', 'draft'), ('state', '=', 'sent')]

# NOT
['!', ('active', '=', False)]

# Nested OR s viacerými podmienkami (pozor na počet operátorov!)
# 3 podmienky = 2x '|'
['|', '|', ('state', '=', 'a'), ('state', '=', 'b'), ('state', '=', 'c')]

# Field-to-field compare NIE JE MOŽNÝ v doméne!
# WRONG: [('date_done', '<=', 'commitment_date')]
# Workaround: computed stored field alebo Python code
```

---

## Typy akcií

### Update Record
Nastaví field hodnoty na aktuálnom alebo súvisiacom zázname.
- Direct value, reference, Python expression
- Viac polí naraz

### Create a New Record
Vytvorí záznam na ľubovoľnom modeli.
- Link Field pre prepojenie s trigger záznamu
- **Obmedzenie**: Nenastaví mandatory fields ak model má constraints → použi Python code

### Execute Python Code
Najflexibilnejší typ. Spustí Python v safe_eval kontexte.

Dostupné premenné:
```python
records        # Recordset trigger záznamu(ov)
record         # Alias pre records (ak je jeden)
env            # Odoo environment
model          # Model instancia
time           # time modul
datetime       # datetime modul
dateutil       # dateutil modul
timezone       # pytz timezone
float_compare  # Float comparison utility
log()          # Logging (server logs)
_logger        # Logger instancia
UserError      # Exception pre user-facing chyby (CAUSES ROLLBACK!)
Command        # x2m command helper (v16+)
```

### Send Email / Send SMS / Post Message
Používa email/SMS templates. Varianty:
- Email (SMTP)
- Message (Discuss — followers vidia)
- Note (interný — len interní users)
- SMS (s alebo bez note)

### Add Followers
Pridá/odoberie followers na zázname.

### Create Activity
Vytvorí aktivitu (úlohu) pre špecifického usera.

### Webhook (v17+)
Pošle POST request na externý URL s JSON payloadom.
Konfigurácia: URL + výber polí do payloadu.

---

## Studio UI

### Vytvorenie automated action cez Studio

1. Otvor model v Studio (ikona Studio v navbar)
2. Klikni **Automations** (alebo Automation Rules)
3. Klikni **New**
4. Nakonfiguruj:
   - **Name**: Pomenuj pravidlo
   - **Model**: Auto-vyplnený podľa kde si
   - **Trigger**: Vyber typ (On Creation, On Update, atď.)
   - **Trigger Fields**: Ak on_write, vyber polia
   - **Apply on**: Domain filter (visual builder)
   - **Before Update Domain**: Domain pred operáciou
   - **Action To Do**: Vyber typ akcie
5. Ak Python code → napíš kód do Code editora
6. **Notes** tab → dokumentuj čo akcia robí

### Studio automated action vs Settings > Technical

| Vlastnosť | Studio | Technical Menu |
|---|---|---|
| Visual condition builder | Áno | Nie (raw domain) |
| Drag-drop výber trigger fields | Áno | Dropdown |
| Syntax highlighting v code editore | Basic | Basic |
| Všetky typy triggerov | Áno | Áno |
| Všetky typy akcií | Áno | Áno |
| Konfigurácia webhook | Áno (v17+) | Áno (v17+) |
| Batch edit viacerých pravidiel | Nie | Áno (list view) |
| Kopírovanie/duplikovanie pravidla | Áno | Áno |
| Export/import | Nie (iba v DB) | Áno (cez module XML) |
| Version control | Nie | Áno (git) |

---

## Studio vs Technical Menu

### Čo Studio ROBÍ lepšie
- Visual field placement (drag-drop)
- Jednoduché automations bez kódu
- Quick prototyping — žiadny restart servera
- Non-developer friendly
- Approval workflows (Enterprise)

### Čo Technical Menu ROBÍ lepšie
- Plný Python prístup (v custom modules, nie safe_eval)
- Version control (git)
- Replicability naprieč inštanciami
- Komplexné computed fields
- Custom modely od nuly
- Scheduled actions (cron) — Studio nemá priamu cron UI
- Performance-critical logika

### Kedy použiť čo

```
Jednoduché: "Keď sa zmení stav na confirmed, pošli email"
→ STUDIO — 5 minút, žiadny kód

Stredné: "Keď sa vytvorí SO nad 10k€, vytvor task v projekte a pridaj manažéra ako follower"
→ STUDIO s Python code — 15 minút

Komplexné: "Cross-module workflow s conditional branching, external API calls, heavy computation"
→ CUSTOM MODULE — Studio tu naráža na safe_eval limity
```

---

## Studio limity a workaroundy

### Funkčné limity

1. **Python** — žiadne importy, safe_eval sandbox, žiadne `__dunder__` prístupy
2. **Create Record** — nezvládne mandatory fields s constraints → použi Python `env['model'].create({...})`
3. **on_change** — nefunguje ak pole zmení INÁ automation → nemožno reťaziť cez on_change
4. **Cascading** — žiadna built-in ochrana proti infinite loops
5. **Complex computed fields** — Studio neumožňuje `@api.depends()` alebo store=True s custom logikou
6. **Export** — Studio customizácie sú v DB, nie v súboroch → nemožno verzionovať

### Známe problémy

(Pozri **[anti-patterns.md](anti-patterns.md)** pre úplný popis: field-name
kolízie, performance, silent failures, mail recursion.)

### Workaroundy

```python
# Delete record (nedá sa cez UI "Create Record" action)
for record in records:
    record.unlink()

# Set mandatory fields (obísť Create Record limitation)
env['project.task'].create({
    'name': record.name,
    'project_id': env.ref('project.default_project').id,  # mandatory
})

# Guard proti cascading
if env.context.get('skip_automation'):
    pass  # skip
else:
    record.with_context(skip_automation=True).write({'state': 'done'})

# Anti-infinite-loop flag
if not env.context.get('from_automation'):
    record.with_context(from_automation=True).write({'field': 'value'})
```

---

## Best practices

### 1. Dokumentuj VŽDY
Notes tab existuje — použi ho. Kto to vytvoril, kedy, prečo, čo robí.

### 2. Buď selektívny s trigger fields
Na on_write VŽDY vyber konkrétne polia. Nikdy nenechaj prázdne — action sa bude spúšťať
pri KAŽDOM save.

### 3. Použi domain filtre
Bez filtra sa akcia spustí na KAŽDOM zázname. Vždy pridaj `filter_domain` na zúženie.

### 4. Testuj na nekritických dátach
Vytvor test záznam, spusti akciu, over výsledok. Network tab v DevTools = reálny error.

### 5. Jeden účel = jedna akcia
Nerob mega-akciu ktorá robí 10 vecí. Rozdeľ na viacero jednoduchých akcií.

### 6. Pozor na performance
Automated action na `sale.order.line` s triggerom on_write bez filtra = spustí sa pri
KAŽDOM uložení KAŽDÉHO riadku. S 500 riadkami = 500 spustení.

### 7. Scheduled actions = stagger
Ak máš viacero cron jobov, nenastavuj všetky na rovnaký čas. Rozložiť.

---

## Debugging

### Server logy
Automated actions logujú do server logov. Hľadaj:
```
base.automation: ... rule triggered
base.automation: ... executing action
```

### Network tab (UI crash)
DevTools → Network → posledný RPC request `/web/dataset/call_kw` → Response payload
obsahuje reálny traceback.

### Testovacia stratégia
1. Vytvor testovací záznam
2. Vykonaj operáciu ktorá by mala triggernúť akciu
3. Over výsledok (field value, created record, email sent)
4. Ak nič → skontroluj:
   - Je akcia active?
   - Sedí trigger type s operáciou?
   - Sú trigger fields správne?
   - Prejdú domain filtre?
   - Nie je chyba v Python kóde? (skontroluj server logy)
