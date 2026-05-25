# Odoo action systém — version history (v8 → v19)

## Obsah

1. [Prehľad verzií](#prehlad-verzii)
2. [Detailný changelog](#detailny-changelog)
3. [Breaking changes](#breaking-changes)
4. [Migračné poznámky](#migracne-poznamky)

---

## Prehľad verzií

| Verzia | Kľúčové zmeny v action systéme |
|---|---|
| **v8** | Základy — základné server actions, multi, object_create/write |
| **v9** | Stabilizácia, lepšia safe_eval |
| **v10** | modul base_automation stabilizovaný |
| **v11** | on_time trigger, trigger_field_ids |
| **v12** | Lepšie UI, rozšírené typy akcií |
| **v13** | Email/SMS/followers typy akcií, vylepšená condition evaluation |
| **v14** | Veľký UI overhaul, Studio integrácia, filter_pre_domain |
| **v15** | Multi-field triggery, time-based vylepšenia |
| **v16** | Webhook, email varianty (Message/Note), SMS varianty |
| **v17** | on_change → "On UI Change", webhook trigger, aktualizácia terminológie |
| **v18** | numbercall/doall odstránené z ir.cron, security hardening |
| **v19** | AI integrácia, Command helper, vylepšený error handling |

---

## Detailný changelog

### v8 (2014) — základy

**Server actions:**
- `ir.actions.server` s basic states: `code`, `object_create`, `object_write`, `multi`
- `condition` field pre predexecution check
- `fields_lines` pre create/write operácie
- Manual trigger cez "More" menu

**Automated actions:**
- `base_automation` modul ako addon
- Basic triggery: on_create, on_write, on_unlink
- Jednoduchý domain filter
- Ešte bez filter_pre_domain

**Safe_eval:**
- Základná sandbox s obmedzenými builtins
- datetime, time moduly dostupné
- Menej reštrikcie ako v novších verziách

### v9-v10 (2015-2016) — stabilizácia

**Zmeny:**
- base_automation sa stáva stabilnejším modulom
- Lepšia dokumentácia safe_eval kontextu
- Vylepšené error handling pri execution
- `record`/`records` premenné stabilizované

**Špecifické pre v10:**
- `<tree>` tag pre list views (ešte pred prechodom na `<list>`)
- UI automation rules zjednodušené

### v11 (2017) — časové triggery

**Novinky:**
- Trigger typ `on_time` / `based_on_time_condition`
- `trg_date_id`, `trg_date_range`, `trg_date_range_type` fields
- `trigger_field_ids` pre on_write — umožňuje špecifikovať KTORÉ polia
- Scheduler pre time-based triggers (default 4h interval)
- Záporný `trg_date_range` = pred dátumom

**Dopady:**
- Konečne možnosť robiť time-based automations bez custom cron kódu
- Trigger field selection dramaticky zlepšuje performance

### v12-v13 (2018-2019) — rozšírené akcie

**v12:**
- Vylepšené UI pre automation rules
- Lepší error reporting pri execution failures
- Rozšírené domain filter možnosti

**v13:**
- **Nové typy akcií**: `email`, `sms`, `followers`
- Email templates integrácia s automated actions
- SMS sending cez automation rules
- Activity creation cez automation
- Lepšia condition evaluation s Python expressions

### v14 (2020) — revolúcia Studio integrácie

**Veľké zmeny:**
- **filter_pre_domain** (Before Update Domain) — NOVINKA
  - Umožňuje zachytiť state transitions (pred + po)
  - Toto je game-changer pre workflow automations
- **Studio UI overhaul** — visual condition builder
- Descriptívnejšie action type názvy v UI
- Vylepšená dokumentácia automated actions
- Studio Automated Actions tab

**Dopady:**
- filter_pre_domain + filter_domain = elegantné state machine patterny
- Studio users môžu vytvárať automation bez Technical Menu

### v15 (2021) — multi-field a čas

**Zmeny:**
- Lepšie multi-field trigger handling
- Vylepšená time-based trigger konfigurácia
- XML-based automation rule creation zdokumentovaná
- Lepší Studio report designer
- Approval workflows začiatok (early)

### v16 (2022) — webhooky a komunikácia

**Novinky:**
- **Webhook action type** — pošle POST request na externý URL
  - JSON payload s vybranými poľami
  - Sample payload preview v konfigurácii
- **Email varianty**:
  - Email (SMTP)
  - Message (Discuss — followers vidia)
  - Note (interný — len interní users)
- **SMS varianty**:
  - SMS (bez note)
  - SMS (s note)
  - Note only
- `on_change` / `on_form_change` trigger zdokumentovaný

**Dopady:**
- Webhook = prvý natívny spôsob integrácie s externým systémom cez automation
- Communication varianty zjednodušujú notification workflows

### v17 (2023) — terminológia a webhooky

**Zmeny:**
- **Premenovanie**: "Based on Form Modification" → "On UI Change"
- **Webhook TRIGGER** — externý systém môže triggerovať automated action
  - Odoo generuje unikátny webhook URL
  - Externý POST → spustí action
- Rozšírené webhook capabilities (inbound + outbound)
- Štandardizovaná dokumentácia action types
- Dark mode support v Studio
- `Command` helper pre x2m operácie dostupný v eval context
- Vylepšený condition builder v Studio

**Dopady:**
- Webhook trigger = Odoo ako event-driven system
- Command helper zjednodušuje x2m zápis:
  ```python
  record.write({'line_ids': [Command.create({'name': 'New line'})]})
  ```

### v18 (2024) — zjednodušenie a security

**Zmeny:**
- **ODSTRÁNENÉ z ir.cron**: polia `numbercall` a `doall`
  - Interval-only scheduling
  - Run-once logika musí byť v kóde metódy
- Vylepšená safe_eval security
  - Prísnejšie dunder reštrikcie
  - Lepší error messages pri forbidden operations
- Vylepšený error handling v automation rules
- Lepšia integrácia s Discuss modulom
- `type()` builtin ODSTRÁNENÝ na SaaS

**Breaking changes:**
- Cron joby ktoré používali numbercall (run X times and stop) musia byť prepísané
- doall (execute missed runs) tiež removed — scheduler je zjednodušený

### v19 (2025) — AI a vyladenie

**Zmeny:**
- AI-powered suggestions pre automation rules
- Lepšie error handling a logging
- Improved webhook capabilities
- Granulárnejšia kontrola execution
- Performance improvements pre large-scale automations
- Wizard defaults: `default_res_ids` (list) preferované nad `default_res_id`

**Safe_eval (SaaS):**
- `type()` definitívne NEFUNGUJE (NameError)
- `hasattr()`, `getattr()` — "forbidden opcode"
- String literals s dunder (napr. `'__test__'`) — FORBIDDEN pri save
- Striktnejšie ako on-premise

---

## Breaking changes

### v14: filter_pre_domain pridaný
- **Nie je breaking** — nové pole, default empty
- Ale automations bez neho sa môžu správať neočakávane pri upgradoch ak logika závisela na implicit pre-condition

### v17: on_change premenované
- `on_change` → "On UI Change" / `on_form_change`
- DB value ostáva `on_change` — iba UI label sa zmenil
- Ale nové pravidlá vytvorené cez Studio môžu mať inú internú hodnotu

### v18: numbercall/doall odstránené
- **BREAKING**: Cron joby s `numbercall != -1` alebo `doall = True` stratia toto správanie
- **Migrácia**: Prepíš run-once logiku do samotnej metódy:
  ```python
  def _cron_one_time_job(self):
      if self.env['ir.config_parameter'].get_param('job_done'):
          return
      # do stuff
      self.env['ir.config_parameter'].set_param('job_done', 'True')
  ```

### v18-19: safe_eval SaaS reštrikcie
- **BREAKING pre SaaS**: `type()`, `hasattr()`, `getattr()` nefungujú
- Kód ktorý ich používal musí byť prepísaný
- Dunder strings v kóde = nemožné uložiť server action

---

## Migračné poznámky

### Upgrade automated actions (v14 → v18/19)

1. **Skontroluj filter_pre_domain** — ak nemáš, over či logika stále funguje
2. **Skontroluj on_change triggery** — overiť UI label vs DB value
3. **Skontroluj cron joby** — odstrániť závislosť na numbercall/doall
4. **Testuj safe_eval kód** — hlavne na SaaS, type()/hasattr()/getattr() nefungujú
5. **Skontroluj dunder strings** — `'__anything__'` v kóde = nemožné uložiť

### Upgrade custom modulov (v16 → v18/19)

1. `<tree>` → `<list>` (od v17, tree deprecated)
2. Cron: odstrániť `numbercall`/`doall` z XML data files
3. Wizard defaults: `default_res_ids` (list) namiesto `default_res_id`
4. Command import: od v17 dostupný v safe_eval context
5. Webhook: nové capabilities pre inbound triggers

### Špecifiká SaaS migrácie

Na SaaS nemáš prístup k:
- Custom modules (iba Studio + automation rules)
- Server filesystem
- Shell/CLI
- Direct SQL (okrem env.cr v server actions)

Všetko musí fungovať cez:
- Studio UI
- Server actions (safe_eval)
- Automated actions
- Scheduled actions (cez UI, nie XML)
