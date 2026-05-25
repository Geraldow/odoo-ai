# Anti-patterns a gotchas v action systéme

Konsolidovaný zoznam footgunov z action systému, ktoré sa objavujú v automated
actions, server actions a cron jobs. Každá položka ukazuje zlú cestu, prečo
zlyháva, a správny pattern.

---

## 1. `raise UserError` po write

**Symptóm:** Server action reportuje úspech, ale zmena dát nepersistuje.

**Príčina:** `UserError` prerušuje transakciu. Akýkoľvek `write()` / `create()` /
`unlink()` ktorý sa vykonal pred raise sa rollbackne.

```python
# ZLE — write je zahodený
record.write({'state': 'confirmed'})
raise UserError('Confirmed!')
```

```python
# SPRÁVNE — pre toast spätnú väzbu po write použi display_notification
record.write({'state': 'confirmed'})
action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {'title': 'Confirmed', 'message': record.name, 'type': 'success'},
}
```

Keď rollback je to, čo chceš (napr. "test write bez persistance"), `UserError`-
po-write je zámerné — pozri safe rollback pattern v skille odoo-server-actions.

---

## 2. Nekonečný loop v automation

**Symptóm:** Write triggeruje automated action, ktorý spraví ďalší write, ktorý
triggeruje ďalší automated action, ktorý prepíše to pôvodné pole…

**Príčina:** Medzi `base.automation` pravidlami neexistuje built-in ochrana
proti cyklom.

```python
# Rule A (on_write, field=state): nastaví state = 'confirmed'
# Rule B (on_write, field=state): nastaví state = 'processing' —
# re-triggeruje filter pre Rule A, infinite loop.
```

```python
# SPRÁVNE — guard cez context key
if env.context.get('skip_auto'):
    # Sme už vnútri automation; bail out
    return
record.with_context(skip_auto=True).write({'state': 'confirmed'})
```

Skombinuj guard s domain filtrom tak, aby pravidlo TIEŽ krátkodobo neprošlo
keď state má už cieľovú hodnotu — najlacnejší filter vyhráva.

---

## 3. O2M trigger trap (parent nevidí zmeny v child)

**Symptóm:** Automated action na `sale.order` s trigger fields `[order_line]`
sa nespustí keď sa riadok pridá/edituje.

**Príčina:** `on_write` sa spúšťa pre record na ktorom sa volal `write()`.
Pridanie alebo edit O2M riadka zapisuje do child modelu (`sale.order.line`),
nie do parenta. `write()` na parente nie je volaný.

```python
# ZLE — automation na sale.order nechytí edity na riadkoch
# Trigger: on_write, fields: [order_line]
```

```python
# SPRÁVNE — daj automation na child model a propaguj nahor
# Automation na sale.order.line, trigger: on_write, fields: [price_subtotal]
# Kód:
order = records.order_id
order.write({'x_studio_lines_changed': True})
# Potom naviaž druhý automation na sale.order ktorý reaguje na
# x_studio_lines_changed, ak je to potrebné.
```

---

## 4. `mail.message` automation rozbije mail gateway

**Symptóm:** Prichádzajúce emaily sa prestanú spracovávať. `mailgateway` logy
ukážu neošetrené exceptions.

**Príčina:** Automated action na `mail.message` s triggerom `on_create`.
Akýkoľvek neošetrený exception sa propaguje cez `mail.thread.message_post()`
do `mail.gateway.process()`, na ktorom catchall závisí.

```python
# ZLE — žiadny guard okolo tela automation
record.write({'x_processed': True})
# Ak vyššie vyhodí chybu (napr. zamknutý record, zlá hodnota), catchall je mŕtvy.
```

```python
# SPRÁVNE — vždy prehltni exception na mail.message automations
try:
    record.write({'x_processed': True})
except Exception:
    # Lepší silent fail než rozbitý prichádzajúci email
    pass
```

Lepšia alternatíva: daj logiku na špecifickejší model (`mail.message` filter
cez `model` je často overkill), alebo použi `ir.cron` na batch-spracovanie
správ mimo hot path gateway.

---

## 5. Nefiltrované automation na frekventovanom modeli

**Symptóm:** Save latencia rastie. Cron/background joby začnú timeoutovať.
Užívatelia sa sťažujú, že ukladanie formulára trvá sekundy.

**Príčina:** Automated action na `res.partner`, `sale.order.line`,
`account.move.line` alebo podobnom — bez `filter_domain`. Pravidlo sa
re-vyhodnocuje pri každom write.

```python
# ZLE — spúšťa sa pri každom save partnera. So 50k partnermi sa každý
# automation na partnerovi stáva bottleneckom.
# filter_domain: []
```

```python
# SPRÁVNE — zúž cez lacnú doménu
# filter_domain: [('customer_rank', '>', 0), ('x_studio_needs_review', '=', True)]
```

Zoraď domain leaves podľa selektivity: najlacnejší discriminátor prvý, aby
väčšina záznamov krátkodobo neprešla ešte pred nákladnými joinmi.

---

## 6. Chýbajúce trigger fields pri `on_write`

**Symptóm:** Rovnaké ako #5 — automation beží pri každom save.

**Príčina:** Pri triggeri `on_write`, nechaním trigger fields prázdnych
znamená, že *akákoľvek* zmena poľa re-vyhodnotí pravidlo.

Fix: vždy vyber najmenšiu množinu polí ktorých zmena reálne pre toto pravidlo
matteruje. Pri `on_create_or_write` sa trigger fields aplikujú na write vetvu.

---

## 7. `on_change` / `on_form_change` nebeží mimo UI

**Symptóm:** Automation funguje pri editácii v UI ale nie pri importoch, API
writeoch alebo iných automations.

**Príčina:** `on_change` je UI-only trigger — spúšťa sa počas renderu
formulára, nie počas ORM `write()`.

Fix: ak potrebuješ logiku v oboch kontextoch, použi `on_write` pre ORM a
duplikuj ľahšiu verziu ako `on_change` pre UI feedback. Alebo daj logiku do
`@api.constrains` / `@api.depends` v custom module.

---

## 8. Wizard default posunutý ako single `res_id` v Odoo 19+

**Symptóm:** Otvorenie wizardu z akcie vyhodí `ValueError` v Odoo 19.

**Príčina:** V 19-tke wizard defaults očakávajú `default_res_ids` (list).
Posielanie `default_res_id` (int) je deprecated a môže vyhodiť chybu podľa
modelu.

```python
# ZLE (v19+) — môže ValueError
action = {'context': {'default_res_id': record.id}}
```

```python
# SPRÁVNE — list forma funguje v 18 aj 19
action = {'context': {'default_res_ids': record.ids}}
```

---

## 9. `sudo()` obchádza všetko — vrátane company scopingu

**Symptóm:** Záznamy sa objavujú cross-company, kontrola ktorú si očakával
(record rule) sa ticho neaplikuje.

**Príčina:** `sudo()` ignoruje ACLs *aj* record rules. Company filtrovanie
žije v record rules — takže sudo search-e vidia všetky companies.

Fix: použi `with_company()` na explicitné nastavenie company, alebo skombinuj
`sudo().with_company(target)` aby si udržal sudo-bypass scope-ovaný.

```python
# Cross-company safe
env['purchase.order'].sudo().with_company(target_company).create({...})
```

---

## 10. Studio field name kolízia (`x_studio_field_1` sufix)

**Symptóm:** Doména ktorá včera fungovala teraz padá na
`Invalid field 'x_studio_approved'`.

**Príčina:** Niekto zmazal a znovuvytvoril Studio pole. Odoo priradí nový
technical name (`x_studio_approved_1`) aj keď label je identický.

Fix: vždy over Technical Name cez *Developer tools → View metadata* predtým
než napíšeš doménu alebo automation kód proti Studio poľu. Ak kontroluješ
pomenovanie, preferuj module-declared polia (bez `x_` prefixu) pred Studio
pre čokoľvek odkazované viacerými automations.

---

## 11. Cron `numbercall` / `doall` v Odoo 18+

**Symptóm:** Cron nakonfigurovaný s `numbercall = -1` v XML vyhodí
`ValueError: Invalid field`.

**Príčina:** `numbercall` a `doall` boli odstránené z `ir.cron` v 18-tke.
Interval je jediný scheduling knob.

Fix: pre "run once" crony, vymaž cron po jeho behu, alebo nastav
`active = False` vnútri kódu cronu.

---

## 12. `numbercall = 1` cron sa auto-nedeaktivuje

**Symptóm:** One-shot cron stále beží.

**Príčina:** Dokonca pred 18-tkou, `numbercall = 1` sa deaktivuje iba po
úspešnom completione. Ak cron vyhodí chybu, counter sa neznižuje.

Fix: zabaľ telo cronu do try/except a nastav `active = False` v success
vetve. V 18+ deaktivuj explicitne:

```python
cron = env.ref('module.ir_cron_once')
cron.sudo().write({'active': False})
```

---

## 13. Použitie `record` / `records` v manuálnej server action

**Symptóm:** Manuálna server action funguje keď je pripojená k modelu A ale
nie k modelu B — končíš s údržbou N kópií tej istej akcie.

**Príčina:** `record` a `records` sú naviazané na model, ku ktorému je SA
pripojená. *Priradený model* SA je vlastnosť jej konfigurácie, nie toho, s čím
chceš operovať.

Fix: choď model-agnostic. Vždy resolvni dáta cez `env[...]`:

```python
# ZLE — viazané na priradený model SA
for rec in records:
    ...

# SPRÁVNE — funguje z akejkoľvek SA, bez ohľadu na priradený model
orders = env['sale.order'].sudo().search([...])
for rec in orders:
    ...
```

Výnimka: `base.automation` pravidlá, kde `records` JE trigger record a
priradený model je zmyslel — odporúčanie sa týka iba manuálnych SAs.

---

## Tabuľka rýchlej diagnostiky

| Symptóm | Prvá vec na overenie |
|---|---|
| Automation sa nespúšťa | Nastavené trigger fields? Príliš striktná doména? Pravidlo active? |
| Automation sa spúšťa príliš často | Chýba doména? Prázdne trigger fields pri `on_write`? |
| Write zmizne | `UserError` po `write()`? → použi `display_notification` |
| Mail gateway rozbitý po edite automation | Neošetrený exception v `mail.message` automation? |
| Cron beží do nekonečna | Pre-18 `numbercall` logika? V 18+ vymaž alebo deaktivuj cron |
| Doména sa naraz rozbije | Studio pole bolo znovuvytvorené a dostalo `_1` sufix |
