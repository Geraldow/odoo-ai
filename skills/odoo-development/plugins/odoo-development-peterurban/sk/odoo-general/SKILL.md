---
name: odoo-general
description: Základný playbook pre Odoo vývoj. Čítajte vždy, keď pracujete s Odoo modulmi, modelmi, poliami, ORM, server-side kódom, pohľadmi (form/list/kanban/search), manifestmi, štruktúrou modulov, deploymentom, Docker workflow, Studiom, record rules, CRUD alebo akoukoľvek Odoo admin/config úlohou. Pokrýva environment/Docker workflow, pravidlá hot-reload, layout module manifestu, tabuľku bežných chýb, ORM vzory, CRUD úskalia, record rules, obnovu Studio pohľadov a deployment postupy. NEPOKRÝVA QWeb/šablóny/reporty (použite odoo-qweb), server action safe_eval (použite odoo-server-actions), externé JSON-RPC/JSON-2 API (použite odoo-api), architektúru action systému a automated actions (použite odoo-actions-master) ani funkčné poradenstvo (použite odoo-skill).
---

Direktívy: Dodržujte striktne. Nepredpokladajte, že štandardná Python/JS logika platí bez Odoo kontextu.

Najprv Google pre arch/fields/xpath vzory. SSH iba pre DB dáta. Deploy First: Upload->Update->Check Logs. Radšej NEPOUŽÍVAJTE research skripty, arch dumpy alebo regex pre-checky, len nechajte používateľa testovať.

**Pre QWeb prácu (PDF/HTML reporty, mail.template body_html, dedičnosť pohľadov cez xpath, t-* direktívy, wkhtmltopdf, úprava ir.ui.view): STOP a najprv si prečítajte odoo-qweb skill.** Tá vlastní: direktívy, t-field/t-out/t-esc, módy dedičnosti, XPath vzory, dvoj-enginový model mail.template, wkhtmltopdf úskalia, maticu migrácie verzií (14-19), finančné reporty, kódovanie (SK/CZ diakritika), debug workflow šablón. Táto skill (odoo-general) NEduplikuje tento obsah.

# 1. Environment, Docker a Workflow
- Restart: docker ps -> docker restart <n> -> docker logs <n> (zachytí zlyhania načítania registry).
- Hot-Reload (náš Docker setup): Zmeny v Pythone => restart kontajnera. XML/JS => -u module.
- Assets: Zmeny v JS/CSS -> -u module -> Clear Assets (Debug Mode) -> Clear Browser Cache.
- Load Order: ACLs -> Record Rules -> Data -> Views (polia musia existovať).
- Migrácie/Prod: Jednorazové skripty držte v post_init / post_migration. Preferujte ORM; raw SQL používajte iba ak je to nevyhnutné.

# 2. Modely a ORM vzory
- Pomenovanie: UI vytvorené = x_ prefix. Kód modulu = bez prefixu.
- M2O pravidlá:
  - Required (required=True): použite ondelete='restrict' alebo 'cascade'; vyhnite sa 'set null' (spôsobuje Registry Load Failure).
- XMLID referencie: Použite env.ref('module.xml_id', raise_if_not_found=False) pre voliteľné referencie.
- Strom logiky:
  - Propagovať M2O -> related (stored).
  - Agregovať O2M -> compute (store=True).
  - Dynamické UI -> @api.onchange (Žiadna biznis logika).
  - Validácia -> @api.constrains (ORM) alebo _sql_constraints (DB).
  - Závislosť od kontextu -> @api.depends_context('company', 'lang').
  - Existence check (obíde ACLs) -> any! / not any! operátory.
- Automation Triggers (O2M): Parent *On Update* ignoruje zmeny O2M riadkov. Triggerujte na Child modeli; write() agregát/status na Parent.
- Create overrides: použite iba @api.model_create_multi; volajte super a vráťte recordset.
- Časové pásma: Display: fields.Datetime.context_timestamp(self, dt). Nikdy nehardkódujte offsety časových pásiem.
- Sequences: Použite self.env['ir.sequence'].next_by_code('code'). Nikdy MAX(id)+1.
- Cache: Po raw SQL/externých zmenách: zavolajte env.invalidate_all() alebo records.invalidate_recordset().
- Server Actions (safe_eval): import blokovaný; použite prednačítané globály. Preferujte record.write(); použite log()/message_post(); iterujte cez records. Wizard defaults (19+): default_res_ids list; default_res_id môže vyhodiť ValueError. Pre "do logic + open wizard": najprv write, vráťte ir.actions.act_window (Automated Actions nemôžu vrátiť UI). Pri wrappingu Window Action podľa ID zmergujte jeho kontext, aby ste zachovali defaulty.

# 3. Akčné tlačidlá a Studio
- Akčné tlačidlá vo view: `domain="..."` môže byť ignorovaný (17+). Preferujte Server Action vracajúci ir.actions.act_window dict s explicitnou doménou + target.
- Studio Field Suffix: Mazanie/znovuvytváranie Studio polí môže vyprodukovať x_field_1. Vždy overte Technical Name pred doménami/akciami.
- Server Action Binding: Ak Studio odpojí vybranú Server Action na tlačidle, vytvorte/zapnite context action; ak je potrebné, napojte podľa action ID.
- Operational vs Analytical polia: Nemiešajte "operational flags" (musia sa po akcii resetnúť) s "analytical history" (mali by byť nemenné).
- API: Použite API Key/heslo. SSO zlyhá s XML-RPC.
- Test Mode: Použite pre manuálne crony / technické akcie na SaaS.

# 4. Frontend (OWL/JS)
- DOM integrita: V DOM spravovanom OWL nepoužívajte node.remove(); použite t-if / t-foreach / classes.
- OWL: Nepoužívajte constructor(); inicializujte v setup().
- Reaktivita:
  - Žiadne deep mutácie. state.items = [...state.items, new].
  - Nepretypujte reaktívne polia (Proxies) na plain JS (poruší Record/Reconciler). Použite gettery.
  - Šablóny: t-inherit: Overte scope (this vs component) a že t-set neprepisuje gettery.
- Async: Sync overrides volajúce async? Použite void this.asyncMethod() alebo await iba ak caller očakáva Promise.
- Services:
  - Registrácia: registry.category("services").add("name", { dependencies: [], start() {} }).
  - Notifikácie: notification.add vracia cleanup. Overrides musia vrátiť cleanup.
- Realtime: Backend env['bus.bus']._sendone -> Frontend bus_service subscribe.

# 5. Bezpečnosť a multi-company
- Vrstvy: ACLs (Access) -> Rules (Filter).
- Rules Trap: [('id', 'in', [])] blokuje VŠETKY záznamy.
- Admin: Iba UID 1 ignoruje pravidlá. Admin skupiny potrebujú explicitné [(1,'=',1)].
- Sudo: Vyhnite sa. Obíde všetky bezpečnostné vrstvy.
- Multi-Company:
  - Default: default=lambda s: s.env.company.
  - Rule (Std): [('company_id', 'in', user.company_ids.ids)].
  - Rule (Shared): ['|', ('company_id', '=', False), ('company_id', 'in', user.company_ids.ids)].
- Obmedzenia domény:
  - Žiadne porovnávanie pole-k-poľu (napr. ('date_done','<=','commitment_date')); denormalizujte do uloženého pomocného poľa.
  - ('field','!=','x') vylučuje False; použite ['|', ('field','=',False), ('field','!=','x')] alebo backfillujte.
  - Domény nad O2M: Jednoduché domény nemôžu spoľahlivo vyjadriť ALL/ANY; denormalizujte status na parent.

# 6. Doménové špecifiká
- Mail (širšie poznámky; rendering mail.template samotný = odoo-qweb skill):
  - Recursion Guard: if self.env.context.get('__guard'): return.
  - Params: scheduled_date je kwarg, NIE context.
  - Mail Gateway: Vyhnite sa Automated Actions na mail.message (najmä *On Create*). Nezachytené výnimky rozbijú catchall. Povinné try/except Exception: pass.
- Preklady: from odoo import _ (NIKDY from self.env).
- CRM (SaaS):
  - crm.stage nemusí mať team_id (Invalid field 'team_id' in leaf); nefilterujte doménou podľa neho.
  - Vyhnite sa vyhľadávaniu konfigurácie podľa mena (preklepy/diakritika). Preferujte XML IDs; inak overené stabilné DB ID.
- Documents:
  - Breadcrumb "Project / Task" != Folder. Označuje link na res_model.
  - Hierarchia je striktne definovaná folder_id / parent_id.
- Inventory: Vyhnite sa zápisu do stock.quant. Použite _update_available_quantity alebo stock.move.
- Picking Automations: V Automated Actions na stock.picking guardujte podľa picking_type_id.code, aby ste sa vyhli zlým flow.
- Accounting (Down Payment):
  - Detekcia: line.is_downpayment (bool). display_type je 'product', nie False.
  - Trigger: "On Update" invoice_line_ids (vyhýba sa duplicitným behom).
- Cron (17+): Žiadny numbercall/doall. Použite interval. Run-once logika v kóde.
- Odstránené (19+): stock.valuation.layer (použite stock.move), hr.employee.base.
- Odoo Sign: Single-line autosizes; použite Multiline pre menší font. Typ poľa je nemenný (recreate = nový Variable Name). Variable Name sa zmení (napr., ..._1) pri recreate; obnovte alebo zápisy ticho zlyhajú. PDF pozadie nemenné; upravte externe. Word zdroj: použite "Wrap Text -> Behind Text" pre priehľadnosť.

# 7. Kritický debug (Create/Write crashe)
Keď UI spadne na create/write (UncaughtPromiseError, 500), UI traceback je často zavádzajúci.
- **Network Tab je autorita**: DevTools > Network > posledný RPC request (/web/dataset/call_kw). Response payload obsahuje skutočný traceback (200 OK + error JSON, 500 crash, alebo 403 security). Server logy sú sekundárne.
- **Zombie Configs** (najbežnejšie po Studio zmenách):
  - ir.default: Hardkódované defaulty pre zmazané/premenované polia. Vyhľadajte model defaulty; zmažte iba rozbité záznamy.
  - ir.actions.act_window context: {'default_x_studio_field': ...} pre neexistujúce polia. Crash na otvorenie formu (onchange) alebo uloženie.
  - Skryté pohľady: Aktívne views z odinštalovaných modulov injektujúce neplatné polia. Archivujte ich.
- **Computed Fields Triage**: Polia s compute=True + store=True crashujú na save. Izolujte: dočasne nastavte store=False (presunie crash zo save na read). NIE JE to fix - iba diagnostika. Potom neutralizujte: nahraďte compute logiku dummy (for rec in self: rec['field'] = False), aby ste zachovali štruktúru bez toxickej logiky.
- **Transaction/Cache**: raise UserError v Server Action = ROLLBACK (zmeny stratené). Použite return display_notification. Po zmenách ir.model.fields / ir.ui.view: Hard Refresh (Ctrl+F5) povinný, inak UI posiela zastaranú schému.
- **DB Integrita**: Ak ORM diagnóza zlyhá (napr. "not-null violation" na voliteľnom poli), použite read-only SQL na kontrolu constraintov/NULLov, o ktorých ORM nevie. INSERT/UPDATE cez SQL obchádza audit/automácie - iba test DB.

# 8. Error Reference (mimo šablón)
QWeb / view / template chyby: pozri odoo-qweb § 16.
| Chyba | Príčina | Riešenie |
| --- | --- | --- |
| Invalid field 'X' in leaf | Doména referuje chýbajúce pole. | Opravte doménu alebo udeľte read access. |
| Registry Load Failure | Required M2O + ondelete='set null'. | Použite restrict/cascade. |

# 9. Migrácia dát / ETL
- Headers/Encoding: CZ/SK exporty bývajú cp1250. Non-ASCII/mojibake: použite df.iloc[:, idx]; dumpnite df.columns + df.head().
- Verifikácia: Skontrolujte vzorové output riadky + kľúčové IDs/kódy. Nikdy neverte iba exit kódom/počtu riadkov.
- Source-first Debug: Ak je output zlý (napr. price=0), SQL-checknite source riadok pred debugovaním mappingu.
- Schema Discovery: Najprv vypíšte tabuľky/stĺpce (sys.tables, INFORMATION_SCHEMA.COLUMNS) pred joinmi; nikdy nepredpokladajte, že mená existujú.
- Schema parity: Nepredpokladajte, že súvisiace datasety zdieľajú stĺpce; overte FK stĺpce pred mappingom.
- Dedup: Stage 1 dropnite klony; Stage 2 premenujte konflikty (zachovajte obidve).
- Veľké base64: chunk reads; držte importy <100MB.

# 10. Odoo 19 / Remote Dev
- Module Install: odoo-bin -i module --stop-after-init (alebo -u pre updaty). Hangs = uncommitnuté transakcie/bežiace inštancie/locks/longpolling, nie CLI. Vyhnite sa shell button_immediate_install hackom.
- File Transfer: cat = nespoľahlivý pre binary/UTF-8 (korupcia/truncation). Pomotaný output = prestaňte používať cat; použite scp, rsync alebo base64 -w0.

Odoo online / SaaS - platia safe_eval limity
čo nebude fungovať:
imports
hasattr
getattr
global
...
