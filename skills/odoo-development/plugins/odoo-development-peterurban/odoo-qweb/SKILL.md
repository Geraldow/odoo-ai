---
name: odoo-qweb
description: Read whenever working with QWeb - PDF/HTML reports, mail.template body_html, view inheritance via xpath, website templates, or any t-* directive. Triggers include 'QWeb', 'report', 'template', 'PDF', 'mail.template', 'inherit_id', 'xpath', 't-field', 't-out', 't-call', 'web.external_layout', 'wkhtmltopdf', 'arch_db', or editing/inheriting/debugging anything in ir.ui.view. Required reading BEFORE editing any .xml file containing templates or view inheritance. Do NOT use for OWL frontend (separate concern), pure SCSS, or non-template Python work.
---

Verified Apr 2026 against Odoo 18/19 SaaS + on-prem. QWeb-specific patterns; assumes odoo-general is also loaded for environment/ORM context.

# 1. Anatomy & Render Chain
- PDF chain (mandatory order): `web.html_container` (UTF-8 meta) -> `t-foreach docs as o` -> `web.external_layout` (company header/footer + paperformat) -> `<div class="page">` (printable area).
- `report_name` on ir.actions.report MUST equal `module.template_id`. Mismatch = 404 on /report/pdf.
- `docs` is auto-injected recordset; convention is `t-as="o"`. Inherited reports: use `o`, do NOT map `docs[0]`.
- `arch_db` (ir.ui.view) is JSONB in 18/19. For SQL LIKE: `arch_db::text`.
- Custom context vars: define `AbstractModel` named `report.<module>.<template_id>` with `_get_report_values(self, docids, data=None)` returning dict with `doc_ids`, `doc_model`, `docs` + extras.

# 2. Directives
| Directive | Meaning |
|---|---|
| `t-if` / `t-elif` / `t-else=""` | Conditional. `t-else` requires empty string value, NOT bare attr |
| `t-foreach="x" t-as="i"` | Loop. `t-as` mandatory |
| `t-set` / `t-value` | Assign. Or body content: `<t t-set="x">html</t>` |
| `t-out` | Escaped output, Markup-aware. Canonical form (15+) |
| `t-esc` | Alias for `t-out`. NOT formally deprecated per 19 docs, but `t-out` preferred |
| `t-raw` | Unescaped. **Deprecated since 15.0** - use `Markup()` + `t-out` instead |
| `t-field="o.f"` | Replaces NODE CONTENT with widget-formatted field |
| `t-options='{"widget":...}'` | Field widget options (JSON) |
| `t-att-X="expr"` | Single dynamic attribute |
| `t-attf-X="...#{expr}..."` | Format-string attribute, `#{}` interpolation |
| `t-call="mod.tmpl"` | Include template. Body accessible as `0` inside callee |
| `t-name` | Inline template (kanban, e.g. `t-name="kanban-box"`) |
| `t-lang="code_or_expr"` | Render block in different lang |
| `t-translation="off"` | Disable extraction (code, IDs) |

Loop auto-vars for `t-as="line"` (active): `line_index` (0-based), `line_size`, `line_first`, `line_last`, `line_value`. **Deprecated** (still work, avoid in new code): `line_odd`, `line_even`, `line_parity`. JS-only deprecated: `line_all`.

`t-call` with parameters - pass via nested `t-set`; body as `0`:
```xml
<t t-call="my_module.alert"><strong>Warning</strong></t>
<!-- callee: <div class="alert"><t t-out="0"/></div> -->
```

# 3. Output: t-field vs t-out vs t-esc/raw
- `t-out`: any expression, no widget formatting. Canonical form for 15+.
- `t-esc`: alias for `t-out`, NOT formally deprecated per Odoo 19 docs. Use `t-out` in new code.
- `t-raw`: unescaped. **Formally deprecated since 15.0**. Use `Markup()` + `t-out`.
- `t-field`: REPLACES the wrapping node's content. Adds widget formatting + i18n + null safety.
- Mixed text + field = wrap field separately; `t-field` on a span containing prefix text DELETES the prefix.

```xml
<!-- WRONG - "Total: " disappears -->
<span t-field="o.amount_total">Total: prefix</span>
<!-- RIGHT -->
Total: <span t-field="o.amount_total"/> for <t t-out="o.partner_id.name"/>
```

HTML fields breaking layout: strip tags, or render via `name` attribute (e.g. `account.tax.description`).

# 4. Field Widgets (t-options)
- Monetary: `t-options='{"widget": "monetary", "display_currency": doc.currency_id}'`
- Date: `t-options='{"format": "dd. MM. yyyy"}'` or `{"widget": "date"}`
- Datetime: `{"widget": "datetime"}`
- Contact: `{"widget": "contact", "fields": ["address","name","phone","email"], "no_marker": True}`
- Float precision: `{"precision": 2}`
- Image (SaaS-safe, no FS access): `<img t-att-src="image_data_uri(doc.image_1920)"/>`
- Barcode: `<img t-att-src="'/report/barcode/?barcode_type=Code128&amp;value=%s' % doc.code"/>`
- Always `&amp;` (not `&`) in URL attributes - bare `&` = XML parse error.

# 5. Inheritance
- Modes via `<template ... inherit_id="..." mode="extension|primary">`. Default = extension.
- Extension: patches parent in place. 95% of work.
- Primary: independent variant, callable separately as `module.id`.
- XPath positions: `before`, `after`, `inside`, `replace`, `attributes`.
- `position="replace"` destroys node permanently. Sparingly.
- `position="attributes"`:
  ```xml
  <xpath expr="//table[@name='lines']" position="attributes">
      <attribute name="class">table table-sm custom</attribute>
  </xpath>
  ```
- Sequence wars: Studio views often sequence 160+. Override with `sequence="200"` if your inheritance gets clobbered.
- Studio: "Edit Sources" often opens PARENT view by default - check "View Name" before editing or you patch the wrong template.
- Recovery: delete accidental/broken Studio views in Technical > Views.

# 6. XPath Patterns
- Target stable classes/field attrs. Examples that survive Odoo updates:
  - `//span[@t-field='doc.name']`
  - `//table[hasclass('o_main_table')]//thead`
  - `//div[@id='informations']` (NOT universal across modules - verify per template)
- Avoid global selectors (`//thead`, `//div`) and content-dependent matches.
- Reliable layout anchors in standard reports: `div.page`, `div.oe_structure`, `table.o_main_table`.
- Top-of-page insert: `//div[@class='page']/div[@class='oe_structure'][1]` position="after". Going `inside div.page` lands at BOTTOM.
- Hide nodes: `class="d-none"` or `t-value="None"`. Avoid `position="replace"` on standard blocks.
- Report structure varies by base layout + installed modules. Verify the actual template arch first; don't assume.

# 7. Visual / Report Workflow
- Ask for visual reference FIRST. Mimic provided structure exactly. Iterate one section at a time, verify each before next.
- Report dev order: identify exact template (ir.ui.view) -> anchor stable -> remove inline styles -> test PDF -> iterate.
- No inline styles. Use `report.css` + prefixed classes via `web.report_assets_common` bundle.
- Guard images with `t-if` to prevent layout collapse on null.
- Radical changes: start from Blank report + custom CSS. Don't fight inheritance with replace chains.

# 8. List / Tree Tag (18+)
- Root tag is `<list>` from Odoo 18 (was `<tree>` in 17 and earlier).
- Inheritance xpath expressions ALSO rename: `xpath expr="//tree"` -> `xpath expr="//list"` in 18+.
- `view_mode` string: `tree,form` -> `list,form` in 18+.
- `ir.ui.view.type` field: `'tree'` kept internally for backwards compat in some places; check the specific model.
- Odoo provides `odoo-bin upgrade_code --from 17.0` CLI to auto-convert on upgrade, but it mis-handles list attributes (create, delete, editable, default_order) in some cases - verify output.

# 9. Mail Template (mail.template) - Two-Engine Model
Two distinct rendering engines on different fields. Mixing syntax = #1 cause of broken templates.

**Engine A: inline_template (Jinja2-like)** for `subject`, `email_from`, `email_to`, `email_cc`, `reply_to`, `partner_to`, `lang`, `scheduled_date` (NOT `report_name` - that field no longer exists on mail.template in 17+):
```python
{{ object.name }}
{{ object.partner_id.name or 'Customer' }}
{{ object.state == 'draft' and 'Quotation' or 'Order' }}
{{ ctx.get('proforma') and 'Proforma' or '' }}
```

**Engine B: QWeb** for `body_html` only - standard t-* directives.

Render flow: `send_mail_batch -> _generate_template -> _classify_per_lang -> _render_field per field (engine depends on field) -> _generate_template_recipients -> _generate_template_attachments`.

Context vars in mail rendering:
- All versions: `object`, `user`, `ctx`, `format_amount(amount, currency)`, `format_date(date)`
- 15+: `format_datetime(dt, tz=None, dt_format='medium')`
- 14+: `is_html_empty(html)` - check effectively-empty HTML field (present in `odoo.tools.mail` from at least 14.0)
- 17+: `company.email_primary_color`, `company.email_secondary_color` - in 17/18 computed from `primary_color`/`secondary_color` with labels "Email Header Color"/"Email Button Color"; in 19 direct-set fields with labels "Email Button Text"/"Email Button Color" and defaults `#FFFFFF`/`#875A7B`

Layout wrappers (`mail.template.email_layout_xmlid`):
- `mail.mail_notification_layout` (900px) - standard
- `mail.mail_notification_light` (590px) - simple
- `mail.mail_notification_layout_with_responsible_signature` (900px, 16+) - includes record's `user_id` signature

Report attachment field renamed in 17:
- 14-16: `<field name="report_template" ref="mod.report_action"/>` + `report_name` was on mail.template for dynamic filename
- 17+: `<field name="report_template_ids" eval="[(4, ref('mod.report_action'))]"/>`. The `report_name` field was REMOVED from mail.template. Dynamic filename comes from `print_report_name` on `ir.actions.report`:
  ```xml
  <record id="report_my_action" model="ir.actions.report">
      <field name="print_report_name">(object.name or 'doc').replace('/', '-')</field>
  </record>
  ```
  This is evaluated with `safe_eval` against `{'object': record, 'time': time}` in `mail.template._generate_template_attachments`.

Mail gotchas (also in odoo-general but critical here):
- Recursion guard: `if self.env.context.get('__guard'): return`
- `scheduled_date` is kwarg, NOT context.
- Avoid Automated Actions on `mail.message` On Create - uncaught exceptions kill catchall. Mandatory `try/except Exception: pass`.

# 10. Translation in Reports (t-lang)
For per-recipient lang (partner-language invoices) - define outer + inner template:
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
Re-browse only needed for translatable record fields. Static labels translate automatically; `country_id.name` etc. need the re-browse or stay in original lang.

# 11. wkhtmltopdf Constraints
- Runs in separate process, NO network. CDN fonts/images = blank or hang.
- Use `web.report_assets_common` bundle (NOT `web.assets_common` / `web.assets_backend` - those don't load in PDFs).
- On-prem only: set `bin_path = C:\Program Files\wkhtmltopdf\bin` in odoo.conf. SaaS handled.
- Google Fonts SCSS pitfall: `@import url('...wght@300;400;500')` - semicolons break SCSS parser. Fix to `wght@300..500` syntax. BEST: bundle .woff2 locally, no @import.

# 12. SaaS Specifics
- No filesystem access from templates. Use `image_data_uri(o.field)` for binary images.
- Custom fonts: bundle .woff2 in module static/, declare in `web.report_assets_common`.
- Test renders via `/report/html/mod.report_name/<id>` first to isolate template vs PDF-engine bugs.

# 13. Version Matrix
| Feature | 14 | 15 | 16 | 17 | 18 | 19 |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Output tag (canonical) | t-esc | t-out | t-out | t-out | t-out | t-out |
| `t-esc` status | active | alias for `t-out`, not formally deprecated | alias | alias | alias | alias |
| `t-raw` status | active | **deprecated** | deprecated | deprecated | deprecated | deprecated |
| `report_template` (M2O) | ✓ | ✓ | ✓ | — | — | — |
| `report_template_ids` (M2M) | — | — | — | ✓ | ✓ | ✓ |
| `mail.template.report_name` field | ✓ | ✓ | ✓ | — | — | — |
| `template_category` field | — | — | ✓ | ✓ | ✓ | ✓ |
| `format_datetime()` ctx | — | ✓ | ✓ | ✓ | ✓ | ✓ |
| `is_html_empty()` ctx | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Root `<list>` tag (was `<tree>`) | — | — | — | — | ✓ | ✓ |
| `email_primary_color` / `email_secondary_color` on res.company | — | — | — | ✓ (header/button, computed) | ✓ (header/button, computed) | ✓ (button text/bg, direct-set, different defaults) |

`web.external_layout` resolves company identically across 17/18/19: `company_id` var -> `o.company_id.sudo()` -> fallback `res_company`. Verified from source. There is NO Odoo 19 migration requiring hand-rolled layouts to switch from `res_company` to `docs[0].company_id`.

# 14. Financial Reports (account.report)
- "Could not expand term X.balance" = Expression Label mismatch.
- Cross-row refs: `RowCode.ExpressionLabel` syntax.
- Expressions evaluate top-down; define dependencies above the row that uses them.
- Set Reverse Balance per line explicitly - do not assume default.

# 15. SK/CZ Encoding
Diacritics work IF:
1. File saved UTF-8 (not cp1250)
2. `web.html_container` used (provides UTF-8 meta)
3. XML decl: `<?xml version="1.0" encoding="UTF-8"?>`
4. Fallback strings (`or 'Vážený zákazník'`) also UTF-8

Symptoms:
- `VáÅ¾ený zákazník` = file read as Latin-1. Re-save UTF-8.
- `?????` = font lacks glyphs. Use system fonts (DejaVu Sans, Arial) or bundle font with full Latin Extended-A coverage.

# 16. Common Errors
| Error | Cause | Fix |
|---|---|---|
| `KeyError: 'format_amount'` | Missing render context helper | Inherit `mail.render.mixin` |
| `AttributeError: NoneType has no attribute X` | Null traversal | `o.field.x or ''` or `<t t-if="o.field">` guard |
| `XMLSyntaxError: EntityRef expecting ;` | Bare `&` in attribute | `&amp;` |
| 404 on /report/pdf | `report_name` ≠ template id | Match exactly: `module.template_id` |
| Encoding garbage | Missing `web.html_container` | Wrap as outermost call |
| Inherited xpath silently no-op | Wrong inherit_id, view archived, sequence outranked | Check Technical > Views; bump sequence to 200 |
| Blank PDF, HTML preview OK | wkhtmltopdf can't parse SCSS or external font | Validate SCSS; remove CDN URLs; check bin_path |
| `UndefinedColumn` | View references field before DB column exists | Comment view -> Upgrade module -> Uncomment -> Upgrade |
| `JSONDecodeError` (SaaS) | Infra glitch OR bad XML | Trace: billing pages F5 = infra, code crash = fix XML |
| `NotFoundError` (JS) | DOM conflict / hidden by external module | Fix `t-if`; check 3rd-party DOM manipulation |
| `Could not expand term X.balance` | Financial report Expression Label mismatch | Fix label; reorder dependency rows above |
| Stale data / UI shows old arch | Cache mismatch after view edit | `invalidate_recordset()` + bus sync + Clear Assets + Ctrl+F5 |
| Mail body sent as plain text | `body_html` invalid/sanitized away, or layout xmlid missing | Validate HTML; check `email_layout_xmlid`. Note: `mail.template.send_mail_batch` does `body = body_html` directly - `subtype_id` is NOT what switches plain vs HTML |

# 17. Debug Workflow
1. HTML mode first: `/report/html/module.report_name/<id>` - bypasses wkhtmltopdf. Isolates template vs PDF engine.
2. Verify `report_name` field == template id. Off-by-one is silent #1 failure.
3. Validate XML well-formedness (mismatched tags, bare `&`, missing `t-as`).
4. Shell test (16+): `env['ir.actions.report']._render_qweb_pdf('module.report_action', [rec.id])` - returns `(bytes, content_type)`. Signature is `_render_qweb_pdf(report_ref, res_ids=None, data=None)` where `report_ref` is XMLID string / ir.actions.report recordset / int id - NOT a model class. Equivalently: `env.ref('module.report_action').report_action(rec)` for the standard button action.
5. Inheritance not applying: check Technical > Views for sequence and active state.
6. Changes not appearing: Debug Mode -> Regenerate Assets Bundles -> Ctrl+F5.
7. Mail template specifically: open in UI, click "Preview" with sample record - shows rendered output without sending.
