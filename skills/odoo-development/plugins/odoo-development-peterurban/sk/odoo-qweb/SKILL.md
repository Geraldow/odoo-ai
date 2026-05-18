---
name: odoo-qweb
description: Čítajte vždy, keď pracujete s QWeb - PDF/HTML reporty, mail.template body_html, dedičnosť pohľadov cez xpath, website šablóny alebo akúkoľvek t-* direktívu. Spúšťače zahŕňajú 'QWeb', 'report', 'template', 'PDF', 'mail.template', 'inherit_id', 'xpath', 't-field', 't-out', 't-call', 'web.external_layout', 'wkhtmltopdf', 'arch_db' alebo úpravu/dedenie/debug čohokoľvek v ir.ui.view. Povinné čítanie PRED úpravou akéhokoľvek .xml súboru obsahujúceho šablóny alebo dedičnosť pohľadov. NEPOUŽÍVAJTE pre OWL frontend (separátny záujem), čisté SCSS ani pre Python prácu bez šablón.
---

Overené apríl 2026 proti Odoo 18/19 SaaS + on-prem. QWeb-špecifické vzory; predpokladá, že odoo-general je tiež načítaná pre environment/ORM kontext.

# 1. Anatómia a render chain
- PDF chain (povinné poradie): `web.html_container` (UTF-8 meta) -> `t-foreach docs as o` -> `web.external_layout` (company header/footer + paperformat) -> `<div class="page">` (tlačiteľná oblasť).
- `report_name` na ir.actions.report MUSÍ sa rovnať `module.template_id`. Nezhoda = 404 na /report/pdf.
- `docs` je automaticky injektovaný recordset; konvencia je `t-as="o"`. Dedičené reporty: použite `o`, NEMAPUJTE `docs[0]`.
- `arch_db` (ir.ui.view) je JSONB v 18/19. Pre SQL LIKE: `arch_db::text`.
- Vlastné context vars: definujte `AbstractModel` pomenovaný `report.<module>.<template_id>` s `_get_report_values(self, docids, data=None)` vracajúcim dict s `doc_ids`, `doc_model`, `docs` + extras.

# 2. Direktívy
| Direktíva | Význam |
|---|---|
| `t-if` / `t-elif` / `t-else=""` | Podmienka. `t-else` vyžaduje prázdnu string hodnotu, NIE holý atribút |
| `t-foreach="x" t-as="i"` | Loop. `t-as` povinné |
| `t-set` / `t-value` | Priradenie. Alebo body content: `<t t-set="x">html</t>` |
| `t-out` | Escapovaný output, Markup-aware. Kanonická forma (15+) |
| `t-esc` | Alias pre `t-out`. NIE je formálne deprecated podľa docs 19, ale `t-out` je preferovaný |
| `t-raw` | Bez escape. **Deprecated od 15.0** - použite `Markup()` + `t-out` |
| `t-field="o.f"` | Nahradí OBSAH UZLA widget-formátovaným poľom |
| `t-options='{"widget":...}'` | Field widget options (JSON) |
| `t-att-X="expr"` | Jeden dynamický atribút |
| `t-attf-X="...#{expr}..."` | Format-string atribút, `#{}` interpolácia |
| `t-call="mod.tmpl"` | Include šablóny. Body prístupné ako `0` vo volanej šablóne |
| `t-name` | Inline šablóna (kanban, napr. `t-name="kanban-box"`) |
| `t-lang="code_or_expr"` | Renderovať blok v inom jazyku |
| `t-translation="off"` | Vypnúť extrakciu (code, IDs) |

Loop auto-vars pre `t-as="line"` (aktívne): `line_index` (0-based), `line_size`, `line_first`, `line_last`, `line_value`. **Deprecated** (stále fungujú, vyhnite sa v novom kóde): `line_odd`, `line_even`, `line_parity`. Iba JS-deprecated: `line_all`.

`t-call` s parametrami - pass cez nested `t-set`; body ako `0`:
```xml
<t t-call="my_module.alert"><strong>Warning</strong></t>
<!-- callee: <div class="alert"><t t-out="0"/></div> -->
```

# 3. Output: t-field vs t-out vs t-esc/raw
- `t-out`: akýkoľvek výraz, bez widget formátovania. Kanonická forma pre 15+.
- `t-esc`: alias pre `t-out`, NIE je formálne deprecated podľa docs Odoo 19. V novom kóde používajte `t-out`.
- `t-raw`: bez escape. **Formálne deprecated od 15.0**. Použite `Markup()` + `t-out`.
- `t-field`: NAHRADÍ obsah obalujúceho uzla. Pridá widget formátovanie + i18n + null safety.
- Zmiešaný text + pole = pole zabaľte separátne; `t-field` na spane obsahujúcom prefix text VYMAŽE prefix.

```xml
<!-- WRONG - "Total: " disappears -->
<span t-field="o.amount_total">Total: prefix</span>
<!-- RIGHT -->
Total: <span t-field="o.amount_total"/> for <t t-out="o.partner_id.name"/>
```

HTML polia rozbíjajúce layout: strip tagy alebo renderujte cez `name` atribút (napr. `account.tax.description`).

# 4. Field Widgets (t-options)
- Monetary: `t-options='{"widget": "monetary", "display_currency": doc.currency_id}'`
- Date: `t-options='{"format": "dd. MM. yyyy"}'` alebo `{"widget": "date"}`
- Datetime: `{"widget": "datetime"}`
- Contact: `{"widget": "contact", "fields": ["address","name","phone","email"], "no_marker": True}`
- Float precision: `{"precision": 2}`
- Image (SaaS-safe, bez FS prístupu): `<img t-att-src="image_data_uri(doc.image_1920)"/>`
- Barcode: `<img t-att-src="'/report/barcode/?barcode_type=Code128&amp;value=%s' % doc.code"/>`
- Vždy `&amp;` (nie `&`) v URL atribútoch - holé `&` = XML parse error.

# 5. Dedičnosť
- Módy cez `<template ... inherit_id="..." mode="extension|primary">`. Default = extension.
- Extension: patchuje parent in place. 95% práce.
- Primary: nezávislý variant, volateľný samostatne ako `module.id`.
- XPath pozície: `before`, `after`, `inside`, `replace`, `attributes`.
- `position="replace"` natrvalo zničí uzol. Šetrne.
- `position="attributes"`:
  ```xml
  <xpath expr="//table[@name='lines']" position="attributes">
      <attribute name="class">table table-sm custom</attribute>
  </xpath>
  ```
- Sequence wars: Studio views často sekvencia 160+. Overrideujte s `sequence="200"`, ak vašu dedičnosť prepisuje.
- Studio: "Edit Sources" často otvorí PARENT view štandardne - skontrolujte "View Name" pred editáciou, inak patchnete zlú šablónu.
- Recovery: zmažte omylom vytvorené/rozbité Studio views v Technical > Views.

# 6. XPath vzory
- Cieľte stabilné triedy/field atribúty. Príklady ktoré prežijú Odoo updaty:
  - `//span[@t-field='doc.name']`
  - `//table[hasclass('o_main_table')]//thead`
  - `//div[@id='informations']` (NIE univerzálny naprieč modulmi - overte per šablónu)
- Vyhnite sa globálnym selektorom (`//thead`, `//div`) a content-dependent matches.
- Spoľahlivé layout kotvy v štandardných reportoch: `div.page`, `div.oe_structure`, `table.o_main_table`.
- Top-of-page insert: `//div[@class='page']/div[@class='oe_structure'][1]` position="after". Ísť `inside div.page` skončí na SPODKU.
- Skryť uzly: `class="d-none"` alebo `t-value="None"`. Vyhnite sa `position="replace"` na štandardných blokoch.
- Štruktúra reportu sa líši podľa base layoutu + nainštalovaných modulov. Overte skutočný template arch najprv; nepredpokladajte.

# 7. Visual / Report Workflow
- NAJPRV si vyžiadajte visual referenciu. Presne napodobnite poskytnutú štruktúru. Iterujte po sekciách, každú overte pred ďalšou.
- Report dev poradie: identifikujte presnú šablónu (ir.ui.view) -> zakotvite stabilne -> odstráňte inline štýly -> otestujte PDF -> iterujte.
- Žiadne inline štýly. Použite `report.css` + prefixované triedy cez `web.report_assets_common` bundle.
- Guardujte obrázky s `t-if`, aby ste zabránili kolapsu layoutu na null.
- Radikálne zmeny: začnite z Blank reportu + custom CSS. Nebojujte s dedičnosťou cez replace reťazce.

# 8. List / Tree Tag (18+)
- Root tag je `<list>` od Odoo 18 (v 17 a skorších to bol `<tree>`).
- Inheritance xpath výrazy sa TIEŽ premenovávajú: `xpath expr="//tree"` -> `xpath expr="//list"` v 18+.
- `view_mode` string: `tree,form` -> `list,form` v 18+.
- `ir.ui.view.type` pole: `'tree'` zachované interne pre backwards compat na niektorých miestach; skontrolujte konkrétny model.
- Odoo poskytuje `odoo-bin upgrade_code --from 17.0` CLI na auto-konverziu pri upgrade, ale v niektorých prípadoch zle spracuje atribúty list (create, delete, editable, default_order) - overte output.

# 9. Mail Template (mail.template) - dvojenginový model
Dva odlišné render enginy na rôznych poliach. Miešanie syntaxe = príčina č.1 rozbitých šablón.

**Engine A: inline_template (Jinja2-like)** pre `subject`, `email_from`, `email_to`, `email_cc`, `reply_to`, `partner_to`, `lang`, `scheduled_date` (NIE `report_name` - to pole v 17+ na mail.template už neexistuje):
```python
{{ object.name }}
{{ object.partner_id.name or 'Customer' }}
{{ object.state == 'draft' and 'Quotation' or 'Order' }}
{{ ctx.get('proforma') and 'Proforma' or '' }}
```

**Engine B: QWeb** iba pre `body_html` - štandardné t-* direktívy.

Render flow: `send_mail_batch -> _generate_template -> _classify_per_lang -> _render_field per field (engine depends on field) -> _generate_template_recipients -> _generate_template_attachments`.

Context vars v mail renderingu:
- Všetky verzie: `object`, `user`, `ctx`, `format_amount(amount, currency)`, `format_date(date)`
- 15+: `format_datetime(dt, tz=None, dt_format='medium')`
- 14+: `is_html_empty(html)` - skontroluje fakticky prázdne HTML pole (prítomné v `odoo.tools.mail` minimálne od 14.0)
- 17+: `company.email_primary_color`, `company.email_secondary_color` - v 17/18 computed z `primary_color`/`secondary_color` s labelmi "Email Header Color"/"Email Button Color"; v 19 priamo nastavované polia s labelmi "Email Button Text"/"Email Button Color" a defaultmi `#FFFFFF`/`#875A7B`

Layout wrappery (`mail.template.email_layout_xmlid`):
- `mail.mail_notification_layout` (900px) - štandard
- `mail.mail_notification_light` (590px) - jednoduchý
- `mail.mail_notification_layout_with_responsible_signature` (900px, 16+) - vrátane podpisu `user_id` záznamu

Pole report attachment premenované v 17:
- 14-16: `<field name="report_template" ref="mod.report_action"/>` + `report_name` bolo na mail.template pre dynamický filename
- 17+: `<field name="report_template_ids" eval="[(4, ref('mod.report_action'))]"/>`. Pole `report_name` bolo ODSTRÁNENÉ z mail.template. Dynamický filename pochádza z `print_report_name` na `ir.actions.report`:
  ```xml
  <record id="report_my_action" model="ir.actions.report">
      <field name="print_report_name">(object.name or 'doc').replace('/', '-')</field>
  </record>
  ```
  Toto sa vyhodnocuje s `safe_eval` proti `{'object': record, 'time': time}` v `mail.template._generate_template_attachments`.

Mail úskalia (sú aj v odoo-general, ale tu kritické):
- Recursion guard: `if self.env.context.get('__guard'): return`
- `scheduled_date` je kwarg, NIE context.
- Vyhnite sa Automated Actions na `mail.message` On Create - nezachytené výnimky zabijú catchall. Povinné `try/except Exception: pass`.

# 10. Preklady v reportoch (t-lang)
Pre per-recipient lang (invoice v jazyku partnera) - definujte outer + inner šablónu:
```xml
<template id="report_invoice">
    <t t-call="web.html_container">
        <t t-foreach="docs" t-as="o">
            <t t-call="my.report_invoice_doc" t-lang="o.partner_id.lang"/>
        </t>
    </t>
</template>
<template id="report_invoice_doc">
    <t t-call="web.external_layout">
        <div class="page">
            <!-- For TRANSLATABLE record fields (country.name, etc.), MUST re-browse: -->
            <t t-set="o" t-value="o.with_context(lang=o.partner_id.lang)"/>
        </div>
    </t>
</template>
```
Re-browse je potrebný iba pre preložiteľné polia záznamov. Statické labely sa prekladajú automaticky; `country_id.name` atď. potrebujú re-browse alebo zostanú v pôvodnom jazyku.

# 11. wkhtmltopdf obmedzenia
- Beží v separátnom procese, ŽIADNA sieť. CDN fonty/obrázky = prázdne alebo hang.
- Použite `web.report_assets_common` bundle (NIE `web.assets_common` / `web.assets_backend` - tie sa nenačítajú v PDFkach).
- Iba on-prem: nastavte `bin_path = C:\Program Files\wkhtmltopdf\bin` v odoo.conf. SaaS vybavený.
- Google Fonts SCSS pitfall: `@import url('...wght@300;400;500')` - bodkočiarky rozbijú SCSS parser. Opravte na `wght@300..500` syntax. NAJLEPŠIE: bundlujte .woff2 lokálne, žiadny @import.

# 12. SaaS špecifiká
- Žiadny prístup k filesystem zo šablón. Pre binárne obrázky použite `image_data_uri(o.field)`.
- Vlastné fonty: bundlujte .woff2 v static/ modulu, deklarujte v `web.report_assets_common`.
- Testujte rendery cez `/report/html/mod.report_name/<id>` najprv, aby ste izolovali bugy šablóna vs PDF-engine.

# 13. Matica verzií
| Feature | 14 | 15 | 16 | 17 | 18 | 19 |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Output tag (kanonický) | t-esc | t-out | t-out | t-out | t-out | t-out |
| Stav `t-esc` | aktívny | alias pre `t-out`, nie formálne deprecated | alias | alias | alias | alias |
| Stav `t-raw` | aktívny | **deprecated** | deprecated | deprecated | deprecated | deprecated |
| `report_template` (M2O) | ✓ | ✓ | ✓ | — | — | — |
| `report_template_ids` (M2M) | — | — | — | ✓ | ✓ | ✓ |
| `mail.template.report_name` pole | ✓ | ✓ | ✓ | — | — | — |
| `template_category` pole | — | — | ✓ | ✓ | ✓ | ✓ |
| `format_datetime()` ctx | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| `is_html_empty()` ctx | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Root `<list>` tag (bol `<tree>`) | — | — | — | — | ✓ | ✓ |
| `email_primary_color` / `email_secondary_color` na res.company | — | — | — | ✓ (header/button, computed) | ✓ (header/button, computed) | ✓ (button text/bg, direct-set, iné defaulty) |

`web.external_layout` rozlišuje company identicky naprieč 17/18/19: premenná `company_id` -> `o.company_id.sudo()` -> fallback `res_company`. Overené zo zdrojáku. NEEXISTUJE Odoo 19 migrácia vyžadujúca ručné layouty na prepnutie z `res_company` na `docs[0].company_id`.

# 14. Finančné reporty (account.report)
- "Could not expand term X.balance" = Expression Label mismatch.
- Cross-row refs: `RowCode.ExpressionLabel` syntax.
- Expressions sa vyhodnocujú top-down; definujte závislosti nad riadkom, ktorý ich používa.
- Nastavte Reverse Balance per line explicitne - nepredpokladajte default.

# 15. SK/CZ kódovanie
Diakritika funguje AK:
1. Súbor uložený UTF-8 (nie cp1250)
2. Použitý `web.html_container` (poskytuje UTF-8 meta)
3. XML decl: `<?xml version="1.0" encoding="UTF-8"?>`
4. Fallback stringy (`or 'Vážený zákazník'`) tiež UTF-8

Symptómy:
- `VáÅ¾ený zákazník` = súbor čítaný ako Latin-1. Uložte znova ako UTF-8.
- `?????` = fontu chýbajú glyphy. Použite system fonty (DejaVu Sans, Arial) alebo bundlujte font s plným pokrytím Latin Extended-A.

# 16. Bežné chyby
| Chyba | Príčina | Riešenie |
|---|---|---|
| `KeyError: 'format_amount'` | Chýbajúci render context helper | Dediete z `mail.render.mixin` |
| `AttributeError: NoneType has no attribute X` | Null traversal | `o.field.x or ''` alebo `<t t-if="o.field">` guard |
| `XMLSyntaxError: EntityRef expecting ;` | Holé `&` v atribúte | `&amp;` |
| 404 na /report/pdf | `report_name` ≠ template id | Zhodujte presne: `module.template_id` |
| Encoding garbage | Chýba `web.html_container` | Zabaľte ako najvonkajší call |
| Zdedený xpath ticho no-op | Zlý inherit_id, view archivovaný, sequence prekonaná | Skontrolujte Technical > Views; bumpnite sequence na 200 |
| Prázdne PDF, HTML preview OK | wkhtmltopdf nevie parsovať SCSS alebo externý font | Validujte SCSS; odstráňte CDN URLs; skontrolujte bin_path |
| `UndefinedColumn` | View refuje pole pred existenciou DB stĺpca | Zakomentujte view -> Upgrade module -> Odkomentujte -> Upgrade |
| `JSONDecodeError` (SaaS) | Infra glitch ALEBO zlé XML | Trace: billing pages F5 = infra, code crash = fix XML |
| `NotFoundError` (JS) | DOM konflikt / skryté externým modulom | Opravte `t-if`; skontrolujte 3rd-party DOM manipuláciu |
| `Could not expand term X.balance` | Financial report Expression Label mismatch | Opravte label; zoraďte dependency riadky vyššie |
| Stale data / UI zobrazuje starý arch | Cache mismatch po view edit | `invalidate_recordset()` + bus sync + Clear Assets + Ctrl+F5 |
| Mail body poslaný ako plain text | `body_html` neplatný/sanitizovaný, alebo chýba layout xmlid | Validujte HTML; skontrolujte `email_layout_xmlid`. Poznámka: `mail.template.send_mail_batch` robí `body = body_html` priamo - `subtype_id` NIE JE to, čo prepína plain vs HTML |

# 17. Debug Workflow
1. Najprv HTML mode: `/report/html/module.report_name/<id>` - obíde wkhtmltopdf. Izoluje template vs PDF engine.
2. Overte `report_name` field == template id. Off-by-one je tiché zlyhanie č.1.
3. Validujte XML well-formedness (nezhodné tagy, holé `&`, chýbajúci `t-as`).
4. Shell test (16+): `env['ir.actions.report']._render_qweb_pdf('module.report_action', [rec.id])` - vracia `(bytes, content_type)`. Signatúra je `_render_qweb_pdf(report_ref, res_ids=None, data=None)` kde `report_ref` je XMLID string / ir.actions.report recordset / int id - NIE model class. Ekvivalentne: `env.ref('module.report_action').report_action(rec)` pre štandardnú button action.
5. Dedičnosť sa neaplikuje: skontrolujte Technical > Views pre sequence a active state.
6. Zmeny sa nezobrazujú: Debug Mode -> Regenerate Assets Bundles -> Ctrl+F5.
7. Mail template špecificky: otvorte v UI, kliknite "Preview" so vzorovým záznamom - zobrazí rendered output bez odoslania.
