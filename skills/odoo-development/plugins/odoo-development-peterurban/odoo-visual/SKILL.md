---
name: odoo-visual
description: Odoo visual customization reference — backend views (form/list/kanban/search), Studio visual changes, PDF reports (paperformat, Document Layout wizard, company branding), mail templates (layout wrappers, color variables), website & portal theming, and asset bundles. Trigger on paperformat, base_document_layout, report_layout, Document Layout wizard, external_layout, primary_color/secondary_color, email_primary_color, company logo/favicon/letterhead, decoration-danger/info/success/warning/muted, widget= (badge/statusbar/monetary/priority/handle/many2one_tags/...), kanban card, optional= attr, invisible= attr, web.assets_backend, web.assets_frontend, web.report_assets_common, web.assets_email, web.external_layout, website theme, portal.portal_layout, "how do I change the color/font/logo/layout of X", "why does my PDF look wrong", "row/field color based on state". Also trigger on demo/edu database setup requests where the visual should match a real customer's website — keywords "demo Odoo", "edu database", "educational database", "demo for customer X", "match website branding", "brand this demo like <company>". For QWeb template syntax, t-field/t-out, mail render engines, wkhtmltopdf font pitfalls → defer to odoo-qweb. For ORM/module/manifest/view-inheritance plumbing → defer to odoo-general.
---

# Odoo Visual Customization — Backend UI → Website → Email → PDF

Verified against Odoo 18/19 (SaaS + on-prem). This skill owns the **visual
decision layer**: which knob controls the look of a given artefact and how
the layers stack. For QWeb mechanics (directives, inheritance XPath, mail
render engines, wkhtmltopdf constraints) defer to **`odoo-qweb`**.

---

## 1. The visual stack

Every visual change maps onto one of these layers. Identify the layer first,
then pick the tool.

```
Layer                        Controlled by                         Edit via
──────────────────────────   ──────────────────────────────────   ──────────────────────
Print (PDF / HTML report)    ir.paperformat + web.external_layout  XML / Studio / wizard
Email notification           mail_notification_layout* + colors    Mail Templates / Company
Website & Portal             website.theme + SCSS variables        Website editor / SCSS
Backend form/list/kanban     ir.ui.view arch + view attributes     Studio / XML inheritance
Widgets & field rendering    JS widget registry + t-options        Custom module (JS)
Assets (CSS/SCSS/fonts)      web.assets_* bundles (see §9)         Module manifest
Branding (logo/colors/font)  res.company + base_document_layout    Settings → Document Layout
```

Bottom row cascades upward: setting `res.company.primary_color` recolors the
backend theme AND the PDF header band AND (v17/18) the email header.

---

## 2. Routing — "where does change X live"

| I want to change... | Layer | Edit here |
|---|---|---|
| Invoice PDF paper size / margins | paperformat | Create `ir.paperformat` record; bind on `ir.actions.report.paperformat_id` (per-report) or on `res.company.paperformat_id` (default) |
| Report header logo | branding | *Settings → Companies → Configure Document Layout* — uploads to `res.company.logo` |
| Report header color band / accent | branding | Document Layout wizard → `primary_color` / `secondary_color` on `res.company` |
| Report layout style (Background/Boxed/Clean/Striped/Bold) | branding | Document Layout wizard → `res.company.report_layout` |
| Font in PDF reports | branding | Document Layout wizard → `res.company.font`; for custom fonts bundle `.woff2` in `web.report_assets_common` |
| Report footer text (terms, VAT#, etc.) | branding | Document Layout wizard → `res.company.report_footer` |
| Row red when `state == 'blocked'` | backend view | `<list decoration-danger="state=='blocked'">` (or `<tree>` ≤17) |
| Field hidden / read-only per record | backend view | `invisible="..."`, `readonly="..."` using Python-domain syntax on the `<field>` |
| Column hidden by default, user can opt-in | backend view | `optional="hide"` (or `optional="show"`) on `<field>` in list |
| Field visible only on certain view | backend view | wrap in `<field invisible="context.get('default_x')">`, or inherit a primary view |
| Monetary formatted with currency | widget | `widget="monetary"` + a `currency_id` field sibling |
| Priority stars, progress bar, handle drag | widget | `widget="priority"` / `widget="progressbar"` / `widget="handle"` |
| Inline colored tag on Many2one | widget | `widget="many2one_tags"` on M2M (or M2O w/ domain) + `color_field` |
| Kanban card color from Integer field | backend view | `<kanban default_group_by="..." default_order="..."><field name="color" />` + `class="oe_kanban_color_{color}"` on root div |
| Kanban card stage dot (green/orange/red) | backend view | Add `kanban_state` field to model + render via `<field name="kanban_state" widget="kanban_state_selection"/>` |
| Email header / button color | email branding | `res.company.email_primary_color` / `email_secondary_color` (see §7 for version semantics) |
| Portal "View Quotation" button color | email/website | Cascades from `email_secondary_color`; portal pages pick up website theme SCSS vars |
| Website primary color | website theme | *Website → Configuration → Website → Theme Colors* (UI) — writes SCSS var overrides |
| Add custom CSS to PDF only | print assets | Add SCSS file to `web.report_assets_common` bundle in `__manifest__.py` |
| Add custom CSS to backend only | backend assets | Add to `web.assets_backend` (NOT `web.assets_common`) |
| Favicon in browser tab | branding | *Settings → Companies → Favicon* (`res.company.favicon`); website-level override on `website.website` |
| Per-company letterhead on reports | branding | Each company configures its own Document Layout; `web.external_layout` resolves via `o.company_id` |
| Chatter on/off for a model | backend view | Studio → Form → toggle chatter (adds/removes `<chatter/>` element in arch) |
| Smart buttons on form top | backend view | `<button class="oe_stat_button" type="object" name="..." icon="fa-..."><field widget="statinfo"/></button>` inside `<div class="oe_button_box">` |
| Status bar colors | backend view | `statusbar_colors="..."` attr on `<header><field name="state" widget="statusbar"/></header>` |
| Group rows in list | backend view | Search view: add `<filter context="{'group_by': 'field_name'}"/>` |

---

## 3. Backend UI — form / list / kanban / search

### View attributes for appearance

These attributes control look without touching Python:

| Attribute | Where it applies | Example | Effect |
|---|---|---|---|
| `invisible="expr"` | field, button, group, page, div | `invisible="state=='draft'"` | Hidden when truthy; uses Python domain context. Replaces `attrs={'invisible': [...]}` in 17+ |
| `readonly="expr"` | field, button | `readonly="state in ('posted','cancel')"` | Locks editing; field is still shown |
| `required="expr"` | field | `required="type=='out_invoice'"` | Conditional mandatory |
| `optional="hide"` / `"show"` | field in list | `<field name="note" optional="hide"/>` | User can toggle column via ⚙ menu; "hide" = off by default, "show" = on |
| `decoration-info` / `-success` / `-warning` / `-danger` / `-muted` / `-bf` / `-it` | `<list>` / `<tree>` | `<list decoration-success="state=='done'">` | Row color + font weight; `-bf` = bold, `-it` = italic |
| `nolabel="1"` | field in form | `<field name="note" nolabel="1"/>` | Suppresses the field's label |
| `colspan="N"` | field, group, element inside form | `<field colspan="4"/>` | How many grid columns to span (default `<group>` is 2 cols) |
| `col="N"` | `<group>` | `<group col="4">` | Number of sub-columns inside this group |
| `string="..."` | any labeled element | `<field string="Delivery Date"/>` | Override label (v17+ replaces old `string` on view inheritance) |
| `widget="..."` | field | see below | Renders field with a specific widget |
| `options="{...}"` | field | `options="{'no_create': True}"` | Widget-specific JSON config |
| `placeholder="..."` | field | `placeholder="e.g. SO001"` | Empty-state hint |
| `help="..."` | field | `help="VAT number"` | Tooltip on hover |
| `groups="base.group_system"` | any | — | Element only visible to users in group |

Note: `attrs={'invisible': ...}` and `states="..."` syntax is **removed in
Odoo 17.0** — use the plain `invisible=`/`readonly=`/`required=` attributes
with Python-domain expressions. Odoo's upgrade CLI migrates most cases; verify
conditional elements after upgrade.

### Common widgets

Pick the right widget before considering CSS. Widget = correct rendering +
correct edit mode + correct keyboard behavior — cheaper than styling.

| Widget | Field type | When to use |
|---|---|---|
| `badge` | char / selection / M2O | Pill-style inline value. Pair with `decoration-*` for color |
| `statusbar` | selection | Top-of-form pipeline: `draft → sent → sale`. `statusbar_colors` for per-stage color |
| `priority` | selection `[('0','Low'),('1','Normal'),...]` | Star ratings |
| `handle` | integer `sequence` | Drag-reorder in list views |
| `monetary` | float | Currency formatting; requires `currency_id` sibling field |
| `percentage` | float | Displays as e.g. `42%` |
| `progressbar` | float / integer | Horizontal bar with label; `options="{'max_value': 100}"` |
| `image` | binary | Renders image; `options="{'size': [90, 90]}"` |
| `image_url` | char | Image loaded from URL (no upload) |
| `html` | html | Rich-text editor (tiptap in v17+) |
| `boolean_toggle` | boolean | iOS-style switch instead of checkbox |
| `selection_badge` | selection | Pill group for quick switching |
| `many2one_tags` | M2M | Tag-style inline M2M; `color_field="color"` for colored tags |
| `many2one_avatar_user` | M2O to `res.users` | Avatar + name inline |
| `radio` | selection | Radio buttons instead of dropdown |
| `char_emojis` | char | Allows emoji insertion |
| `url` | char | Clickable link |
| `email` | char | Click to `mailto:` |
| `phone` | char | Click to `tel:` |
| `float_time` | float | Hours as `HH:MM` |
| `datetime` | datetime | Standard; use `options="{'rounding': 15}"` for stepper |
| `daterange` | date / datetime | Two-field date-range picker (requires M2O or sibling field) |
| `statinfo` | integer / float | Value + label pair inside smart buttons |

For widget authoring (JS) see Odoo documentation — out of scope here.

### Kanban cards

```xml
<kanban default_group_by="stage_id" default_order="priority desc, id">
    <field name="color"/>           <!-- optional: integer field 0-11 for card color -->
    <field name="kanban_state"/>    <!-- optional: selection for stage dot -->
    <templates>
        <t t-name="kanban-box">
            <div t-attf-class="oe_kanban_card oe_kanban_global_click oe_kanban_color_#{record.color.raw_value}">
                <div class="o_kanban_record_top">
                    <strong><field name="name"/></strong>
                    <field name="kanban_state" widget="kanban_state_selection"/>
                </div>
                <div class="o_kanban_record_body">
                    <field name="partner_id"/>
                    <field name="amount_total" widget="monetary"/>
                </div>
                <div class="o_kanban_record_bottom">
                    <img t-att-src="kanban_image('res.users', 'avatar_128', record.user_id.raw_value)"
                         class="oe_avatar" t-att-title="record.user_id.value"/>
                </div>
            </div>
        </t>
    </templates>
</kanban>
```

Conventions: root `<div>` needs `oe_kanban_card` + `oe_kanban_global_click`;
color classes are `oe_kanban_color_0` … `oe_kanban_color_11` (11 slots in the
standard palette); progressbar per group uses `<progressbar field="..."
colors='{"done":"success","blocked":"danger"}'/>` as a direct child of
`<kanban>`.

### List views — tag change in 18+

Root tag `<tree>` → `<list>` in Odoo 18. XPath expressions in inherited views
must match: `xpath expr="//tree"` → `xpath expr="//list"`. `view_mode` string
`tree,form` → `list,form`. See **odoo-qweb §8** for the full 17→18 migration
matrix and the caveats with Odoo's `upgrade_code` CLI.

### Search view

- `<filter name="..." string="..." domain="[...]" />` — named filter, clickable chip
- `<filter name="..." context="{'group_by': 'field_name'}" />` — enables group-by in search dropdown
- `<searchpanel>` with `<field>` children = left-side facet panel (v13+)
- Hidden-by-default filters use `invisible="1"` for context-only defaults

### Sequence wars (visual inheritance)

- Core views: `sequence < 100`
- Addon inherits: `sequence` 100–159
- Studio views: `sequence ≥ 160`
- Your override that must win over Studio: `sequence >= 200`

Mentioned also in odoo-skill's implementation playbook; reiterated here
because it's the #1 "my CSS/widget change doesn't apply" cause.

---

## 4. Studio visual layer

### What Studio can do

- Drag-drop fields, groups, tabs, notebook pages inside form views
- Change widget via dropdown (monetary, badge, statusbar, etc.)
- Set `decoration-*` via "Conditional Formatting" wizard on list views
- Toggle chatter, activities, followers on a model
- Create kanban views with color picker for `color_field`
- Add a Studio Report (basic table / label), edit inside Studio's WYSIWYG
- Edit email template subject/body with minimal editor

### What Studio can NOT do

- Custom kanban card HTML beyond slotting fields — use module XML
- Report templates of non-trivial structure — Studio Reports only handle simple table outputs; complex invoices require QWeb XML inheritance
- Paperformat — only via *Settings → Technical → Paper Format*
- Asset bundle additions (custom SCSS/fonts)
- Custom OWL widgets
- View-level attribute edits that Studio doesn't expose in the UI — fall back to *Developer → Edit View* (advanced) or an XML-inheriting module

### Studio gotchas

- Field deletion + recreation yields `x_studio_field_1` suffix — see **odoo-actions-master/references/anti-patterns.md §10**. Always verify Technical Name via *Developer tools → View Metadata* before writing domains, decorations, or automation code against a Studio field.
- "Edit Sources" in Studio opens the **parent** view by default — confirm "View Name" matches the view you intended to patch or you'll inject nodes into the wrong template (**odoo-qweb §5**).
- Studio-added SCSS is stored in `ir.asset` records, not module files. Export via Studio backup — don't rely on git for versioning.

---

## 5. PDF reports — visual decision surface

### Document Layout wizard — the 80% solution

Menu: *Settings → General Settings → Companies → Configure Document Layout*.

This wizard is the main control surface. It writes directly to
`res.company`:

| Wizard field | `res.company` field | Effect |
|---|---|---|
| Layout (radio: Background / Boxed / Clean / Striped / Bold) | `report_layout` | Picks one of 5 XML IDs used as `web.external_layout` variant |
| Company Logo | `logo` | PNG/JPG; used in header and fallback favicon |
| Company Tagline | `report_header` | Short line above header separator |
| Footer | `report_footer` | Bottom-of-page text (VAT #, address, terms) |
| Primary Color | `primary_color` | Header accent band, table header background |
| Secondary Color | `secondary_color` | Buttons in portal/email, secondary accents |
| Font | `font` | Report font (Lato / Roboto / Open Sans / Montserrat / Oswald / Raleway / Tajawal) |
| Paper Format | `paperformat_id` | Default paperformat for all reports from this company |

The preview on the right re-renders as you change inputs. For multi-company
installs, re-run per company — each company's letterhead is independent.

### The 5 layout variants

All live in the `web` module, toggled via `res.company.report_layout`:

| `report_layout` value | XML ID | Look |
|---|---|---|
| `background` | `web.external_layout_background` | Full-page background image + overlay text |
| `boxed` | `web.external_layout_boxed` | Thick colored border box |
| `clean` | `web.external_layout_clean` | Minimalist, thin horizontal rule |
| `striped` | `web.external_layout_striped` | Colored stripe across header + footer |
| `bold` | `web.external_layout_bold` | Heavy header, large company name |

`web.external_layout` itself (the umbrella template) dispatches based on
`company.report_layout` to the right variant.

### Paperformat

Model: `ir.paperformat`. Stock records: `base.paperformat_us` (Letter),
`base.paperformat_euro` (A4 with 40mm header/30mm footer).

Fields to know:

| Field | Meaning |
|---|---|
| `format` | `A4` / `A5` / `Letter` / `Legal` / `Tabloid` / `Custom` |
| `page_height` / `page_width` | Only if `format='Custom'`; in mm |
| `orientation` | `Portrait` / `Landscape` |
| `margin_top`, `margin_bottom`, `margin_left`, `margin_right` | mm |
| `header_spacing` | mm between header and page body (default 35 for EU, 10 for US) |
| `header_line` | Boolean — horizontal rule under header |
| `dpi` | PDF resolution, default 90; bump to 150 for high-res images |

Binding priority (first match wins):
1. `ir.actions.report.paperformat_id` — per-report override (most common)
2. `res.company.paperformat_id` — company default
3. Fallback: Odoo picks `base.paperformat_euro`

Creating a custom paperformat (XML):

```xml
<record id="paperformat_custom_narrow" model="ir.paperformat">
    <field name="name">Narrow A4</field>
    <field name="format">A4</field>
    <field name="orientation">Portrait</field>
    <field name="margin_top">25</field>
    <field name="margin_bottom">15</field>
    <field name="margin_left">10</field>
    <field name="margin_right">10</field>
    <field name="header_spacing">15</field>
    <field name="dpi">90</field>
</record>

<!-- Bind it to the invoice report -->
<record id="account.account_invoices" model="ir.actions.report">
    <field name="paperformat_id" ref="paperformat_custom_narrow"/>
</record>
```

### Fonts in PDF

wkhtmltopdf runs in a separate process with no network access. CDN `@import`
URLs blank or hang.

Correct recipe:
1. Bundle `.woff2` files in your module: `static/src/fonts/MyFont-Regular.woff2`
2. Declare in `__manifest__.py`:
   ```python
   'assets': {
       'web.report_assets_common': [
           'mymodule/static/src/fonts/myfont.scss',
       ],
   }
   ```
3. In `myfont.scss`:
   ```scss
   @font-face {
       font-family: 'MyFont';
       src: url('/mymodule/static/src/fonts/MyFont-Regular.woff2') format('woff2');
       font-weight: 400;
   }
   body, .report_body { font-family: 'MyFont', sans-serif; }
   ```

**Not** `web.assets_common` — that bundle doesn't load in PDFs. See
**odoo-qweb §11** for the full wkhtmltopdf constraint list.

### Stable inheritance anchor points

For inheriting an Odoo report template (via QWeb XPath — syntax in
**odoo-qweb §6**), these CSS classes survive Odoo updates:

- `div.page` — printable body area
- `div.oe_structure` — drop-zone blocks inside `div.page`
- `table.o_main_table` — the main line-items table in most standard reports
- `div#informations` — address / order info block (varies per module — verify)

Avoid targeting raw `//thead`, `//div`, or content-dependent selectors.

### Report-level overrides vs wizard

| Change | Do it via |
|---|---|
| Logo / color / font / footer / paperformat for ALL reports from a company | Document Layout wizard |
| Paperformat for ONE specific report | `paperformat_id` on that `ir.actions.report` |
| Layout arch of ONE specific report | Inherit its template via QWeb XPath |
| CSS for a specific report | Add SCSS to `web.report_assets_common`, target report-specific class |
| Different logo in one company's invoice vs its quotations | Inherit each report's external_layout call and swap `o.company_id.logo` |

---

## 6. Mail templates — visual

Two distinct layers. Get the layer right before anything else.

### Outer wrapper — `mail.template.email_layout_xmlid`

The wrapper supplies the header, footer, "View / Pay" button styling, and the
overall container width. Pick one:

| Layout XML ID | Width | Notes |
|---|---|---|
| `mail.mail_notification_layout` | 900px | Default standard layout |
| `mail.mail_notification_light` | 590px | Simpler, narrower (for terse confirmations) |
| `mail.mail_notification_layout_with_responsible_signature` | 900px (v16+) | Same as standard + record's `user_id` signature block |

Custom wrapper: create an `ir.ui.view` of type `qweb` that calls
`<t t-call="mail.message_notification_email"/>` with the right variables;
reference its XML ID from `email_layout_xmlid`. Easiest path: inherit
`mail.mail_notification_layout` and patch what you need.

### Inner body — `body_html`

QWeb + inline-template engine per field (two engines — **odoo-qweb §9**).
This skill does not duplicate that content.

### Color variables on `res.company` — version matrix

| Field | v17 | v18 | v19 |
|---|---|---|---|
| `email_primary_color` | computed from `primary_color`, label **"Email Header Color"** | same | direct-set, label **"Email Button Text"**, default `#FFFFFF` |
| `email_secondary_color` | computed from `secondary_color`, label **"Email Button Color"** | same | direct-set, label **"Email Button Color"**, default `#875A7B` |

Consequence: on v19 changing `primary_color`/`secondary_color` via the
Document Layout wizard no longer automatically shifts the email colors —
update the email-specific fields too. On v17/v18 they follow automatically.

### Preview workflow

Each `mail.template` form has a *Preview* button (top-right) that renders
against a sample record. Use it before sending — catches 90% of issues
(null-traversal errors, missing layout wrapper, broken inline styles) without
polluting a customer's inbox.

Common issues: body sends as plain text → `body_html` got sanitized to empty,
OR `email_layout_xmlid` is missing. `mail.template.send_mail_batch` does
`body = body_html` directly; `subtype_id` does NOT toggle plain vs HTML (see
**odoo-qweb §16** for the full error table).

---

## 7. Website & Portal theming

### Theme hierarchy

- `website.theme` records → one theme active per `website.website`
- Themes override SCSS variables via module asset declarations:
  `$o-color-1` through `$o-color-5` (primary through quinary), `$o-theme-font-family`, `$o-headings-font-family`
- These cascade into `web.assets_frontend`

### Portal vs Website

- **Website** = public, `/` and below. Uses full theme.
- **Portal** = authenticated customer pages (`/my`, `/my/orders`, `/my/invoices`). Uses a trimmed bundle — same theme colors, different layout (sidebar).

Template ancestors:
- Website page: `website.layout` → your page template
- Portal page: `portal.portal_layout` → `portal.portal_sidebar` → your page template

### Overriding colors — UI path

*Website → Configuration → Website → Theme* — color pickers + font pickers.
This writes SCSS variable overrides into an `ir.asset` record with
`bundle='web.assets_frontend'`.

### Overriding colors — module path

```python
# __manifest__.py
'assets': {
    'web.assets_frontend': [
        ('after', 'website/static/src/scss/options/colors/default_color_palette.scss',
         'mymodule/static/src/scss/variables.scss'),
    ],
}
```

```scss
// mymodule/static/src/scss/variables.scss
$o-color-1: #0055AA;   // Primary
$o-color-2: #F5F5F5;   // Secondary / Muted
```

### Email-to-portal color cascade

Email template button colors resolve via `{{ object.company_id.email_secondary_color }}`.
When a customer clicks "View Quotation" in the email, they land on the portal
which renders the same company's website theme. Misalignment between email
color (company field) and website color (theme SCSS) is the most common
visual bug — set both explicitly.

---

## 8. Asset bundles — which bundle for what

One-line summaries. Pick the right bundle; don't mix.

| Bundle | Scope | Loaded in |
|---|---|---|
| `web.assets_backend` | Backend web client (OWL views, widgets, internal SCSS) | Authenticated `/web` |
| `web.assets_frontend` | Public website + portal | Non-auth pages + `/my/*` |
| `web.report_assets_common` | PDF & HTML report rendering | Inside the wkhtmltopdf sub-process |
| `web.assets_email` | Email body rendering | `mail.template.body_html` QWeb pass |
| `web.assets_qweb` | Backend QWeb JS templates (OWL registry) | Backend only |
| `web.assets_common` | Shared backend + frontend | Both; **NOT PDFs** |
| `web.assets_tests` | QUnit tests | `/web/tests` only |

**Most-common mistake:** adding font/CSS to `web.assets_common` expecting PDFs
to pick it up. They won't — PDFs see only `web.report_assets_common`. Same
for backend-only styling accidentally added to `web.assets_common` — that
leaks into the public website.

Bundle manipulation operators in `__manifest__.py`:
- `'path/to/file.scss'` — append
- `('after', 'target', 'path/to/file.scss')` — insert after
- `('before', 'target', 'path/to/file.scss')` — insert before
- `('replace', 'target', 'path/to/file.scss')` — replace
- `('remove', 'target')` — remove from bundle
- `('prepend', 'path/to/file.scss')` — prepend to bundle

---

## 9. Company branding — full surface

`res.company` fields that control appearance:

| Field | What it styles |
|---|---|
| `logo` | Report header, portal navbar, email header |
| `favicon` | Browser tab icon (fallback — website has its own) |
| `primary_color` | Backend theme accent, report header band |
| `secondary_color` | Buttons in reports / emails / portal |
| `email_primary_color` | See §7 version table |
| `email_secondary_color` | See §7 version table |
| `font` | Report font (not backend — backend font is global) |
| `report_layout` | Which of 5 external_layout variants to use |
| `paperformat_id` | Default paperformat when a report doesn't specify one |
| `report_header` | Short tagline above report header |
| `report_footer` | Bottom-of-page legal text |

### Favicon — website vs company

- Company favicon (`res.company.favicon`) → backend tab
- Website favicon (`website.website.favicon`) → public site tab (overrides company)

Both are ir.attachment under the hood; high-res PNG or ICO.

### Multi-company reports

Each `res.company` configures its own Document Layout independently. In a
report template, `web.external_layout` resolves via `o.company_id.sudo()` so
the right letterhead loads per document. Don't hand-roll `res_company` —
the built-in resolution works on 17/18/19 (verified — see **odoo-qweb §13**).

---

## 10. Debugging — "why does this look wrong?"

Decision tree. Walk it top-to-bottom on every visual bug:

1. **Inspect element in browser** → which bundle is the rule in?
   - Class starts with `.o_` → `web.assets_backend`
   - Class starts with `.s_`, `.o_website_` → `web.assets_frontend`
   - Not in any bundle → it's inline on the HTML (search arch)

2. **Change applied but UI shows old** → *Debug Mode → Regenerate Assets Bundles → Ctrl+F5*. Odoo caches bundles aggressively.

3. **View attribute ignored** → a higher-sequence view overrides. Check:
   *Settings → Technical → Views → filter by model → sort by sequence desc*.
   Studio views sit at ≥160; bump yours to 200+.

4. **Decoration not applying** → domain expression is falsy. Test:
   `decoration-danger="state=='blocked'"` requires `state` to be a field in the
   list (add via `<field name="state" invisible="1"/>` if you don't want it shown).

5. **PDF looks different from HTML preview** → wkhtmltopdf limitation
   (**odoo-qweb §11**). Try `/report/html/<xmlid>/<id>` to isolate template
   bugs from PDF-engine bugs.

6. **Report header wrong company** → `o.company_id` is `False` OR the report
   passes `docs` of mixed companies. Log `o.company_id` first thing in the
   template.

7. **Email preview OK, real send broken** → `email_layout_xmlid` is null or
   custom layout raised an error (errors on layout don't propagate — they
   silently fall back to no-wrapper). Check with `_render_template` shell
   test.

8. **Kanban color not working** → (a) `color` field not Integer on the model,
   (b) you forgot `<field name="color"/>` declaration in the kanban arch,
   (c) palette slots are 0–11; value 12 silently wraps.

9. **Paperformat changed but PDF still A4** → report has its own
   `paperformat_id`; company-default is ignored. Clear the report's
   `paperformat_id` to use company default, or override it explicitly.

10. **Portal button color wrong** → company's `email_secondary_color` ≠
    website theme `$o-color-1`. Align both.

11. **Backend badge decoration only bold, no color** → you used `decoration-bf`
    instead of `decoration-info`. `-bf` is bold modifier only.

---

## 11. Version matrix

| Feature | 17 | 18 | 19 |
|---|:-:|:-:|:-:|
| Root tag for list views | `<tree>` | `<list>` | `<list>` |
| `attrs={'invisible': ...}` syntax | removed | removed | removed |
| `states="..."` attribute | removed | removed | removed |
| Plain `invisible="..."` / `readonly="..."` / `required="..."` | ✓ | ✓ | ✓ |
| `email_primary_color` source | computed | computed | direct-set |
| `email_primary_color` label | "Email Header Color" | "Email Header Color" | "Email Button Text" |
| `email_primary_color` default | (from primary) | (from primary) | `#FFFFFF` |
| `email_secondary_color` source | computed | computed | direct-set |
| `email_secondary_color` default | (from secondary) | (from secondary) | `#875A7B` |
| `mail.mail_notification_layout_with_responsible_signature` | ✓ (since 16) | ✓ | ✓ |
| Document Layout wizard | `web.base_document_layout` | same | same |
| Studio Reports (WYSIWYG) | ✓ | ✓ | ✓ |
| `chatter` as dedicated element | `<chatter/>` | `<chatter/>` | `<chatter/>` |
| Tiptap rich-text editor in `html` widget | ✓ | ✓ | ✓ |

---

## 12. Cross-references

| If you need... | Go to |
|---|---|
| QWeb directives, t-field / t-out / t-call, XPath syntax | **odoo-qweb** |
| `mail.template` two-engine render model (Jinja2 + QWeb) | **odoo-qweb §9** |
| wkhtmltopdf pitfalls, font embedding mechanics, PDF-only CSS debugging | **odoo-qweb §11** |
| `web.external_layout` company resolution details | **odoo-qweb §13** |
| View inheritance plumbing, Studio view recovery, zombie configs | **odoo-general** |
| Automating visual changes (e.g. auto-set kanban color on state change) | **odoo-actions-master** + **odoo-server-actions** |
| Safe_eval rules for any Python you write in a visual-driven server action | **odoo-server-actions** |
| Reading `res.company` / `ir.ui.view` / `ir.paperformat` via external API | **odoo-api** |
| Functional consulting — "where does the customer click" | **odoo-skill** |
| Project-level decisions — Studio vs module, sequence convention | **odoo-skill/references/implementation-playbook.md** |
| Studio field-name collision (`x_studio_field_1` suffix) | **odoo-actions-master/references/anti-patterns.md** §10 |

---

## 13. Quick workflow — "customer sent a mockup, now what"

1. **Map** — walk through the mockup element-by-element and assign each to a layer (§1). That tells you which tool to reach for.
2. **Branding first** — open Document Layout wizard, set logo, colors, footer, font, paperformat. That covers 60–80% of most mockups before any code.
3. **Report-specific tweaks** — identify which Odoo report template(s) need edits; inherit via QWeb XPath (**odoo-qweb §5–6**). Prefer `position="attributes"` over `position="replace"` — safer on upgrade.
4. **Backend UI polish** — Studio for field placement, widget choice, decoration. Fall back to module XML for anything Studio can't express.
5. **Website & portal** — align SCSS theme vars to the same primary/secondary, update email colors on `res.company` explicitly in v19+.
6. **Test in both HTML and PDF** — `/report/html/<xmlid>/<id>` first, then PDF. Different rendering engines catch different bugs.
7. **Multi-company check** — if the customer has more than one company, log in as a user from each and verify the layouts render with that company's letterhead.

---

## 14. Workflow — demo/edu setup from a customer's live website

When the user asks you to visually brand a demo or edu Odoo database for a
specific customer (phrasings like *"demo pre XYZ s.r.o."*, *"edu databáza pre
klienta"*, *"nabrand this demo for <company>"*, *"make it look like their
website"*), **do not guess colors or fonts**. Follow this workflow:

### Step 1 — Always ask for a reference first

Before changing anything in Odoo, ask the user:

> **Máš URL stránky klienta, podľa ktorej mám naladiť branding?** (Do you have
> the customer's website URL to use as a reference for branding?)
> - Ak áno: pošli link — stiahnem a extrahujem farby, fonty, logo
> - Ak nie: stačí mi oficiálny brand kit (logo SVG/PNG, HEX kódy farieb, názvy fontov)
> - Ak nemáš ani to: povedz mi aspoň odvetvie / náladu (corporate modrý, minimalistický, warm retail, tech startup, ...)

If the user gives a URL, use `WebFetch` on it. If they give a brand kit
attachment, read it. If neither, fall through to the generic defaults at the
end of this section.

### Step 2 — Extract brand assets (priority order)

When you have a URL, look in this order and **stop at the first reliable
source**:

1. **Dedicated brand / media / press page**
   - Try `/brand`, `/brand-guidelines`, `/press`, `/media-kit`, `/about/brand`, `/styleguide`
   - Also look for a footer link "Press" / "Brand" / "Media"
   - These pages often publish HEX codes, font names, and a logo SVG explicitly — use them verbatim.

2. **CSS custom properties (design tokens)**
   - Fetch the homepage. Search computed styles or inline CSS for variables like:
     `--primary`, `--primary-color`, `--brand-primary`, `--color-primary`, `--accent`, `--secondary`, `--bg-brand`, `--color-brand-1`
   - Modern sites (Tailwind, Bootstrap-custom, design-system builds) expose the palette via `:root { --... }`. Grab those HEX codes directly.

3. **Inline styles + stylesheet rules for hero/header/button**
   - The color used on the primary CTA button (`.btn-primary`, `button.cta`, first hero action) is almost always the brand primary.
   - Link hover color, navbar background, and heading color often encode secondary.

4. **Favicon / logo**
   - `<link rel="icon">`, `<link rel="apple-touch-icon">` — download for favicon.
   - `<img>` with class matching `/logo/i`, `alt` containing "logo", or `src` containing "logo" — download for report logo.
   - If multiple exist, prefer SVG over PNG over JPG. Prefer the one in the site header.

5. **Fonts**
   - Check `<link href="https://fonts.googleapis.com/...">` / `@font-face` declarations / `font-family` on `body` and `h1, h2, h3`.
   - If it's a Google Font, note the family name exactly as listed (e.g. `"Inter"`, `"Open Sans"`, `"Roboto"`); Odoo's Document Layout wizard only supports: Lato, Roboto, Open Sans, Montserrat, Oswald, Raleway, Tajawal — map the customer's font to the closest Odoo-supported one and flag the substitution.

### Step 3 — Fallback when the page has no explicit brand info

If steps 1–4 above don't yield clean values (e.g., site uses a CMS theme with
mixed colors, or the stylesheet is obfuscated):

- **Screenshot → dominant color analysis**: open the homepage, capture 2–3
  screenshots (hero section, nav, footer). Identify the 2 most-used
  non-neutral colors across these — those become primary + secondary.
- **Heading font from rendered text**: inspect the hero heading and main
  navigation in DevTools; note the `font-family` chain's first non-fallback
  name.
- **Body font**: same, from paragraph text.
- Logos and images: always take directly from the page; never regenerate.

### Step 4 — Report the extracted brand sheet BEFORE applying

Present findings as a table the user can eyeball:

```
Brand extracted from <URL>:

  primary_color:           #RRGGBB   (source: --primary CSS var)
  secondary_color:         #RRGGBB   (source: .btn-primary bg)
  email_primary_color:     #RRGGBB   (v19: direct-set; use primary)
  email_secondary_color:   #RRGGBB   (v19: direct-set; use secondary)
  font (Odoo-mapped):      Inter → Roboto   (Inter not in wizard; closest)
  logo:                    <downloaded SVG path>
  favicon:                 <downloaded PNG path>
  report_footer (proposed): "<tagline from homepage> · <VAT from footer>"
```

Wait for confirmation before writing anything to Odoo. Flag any guesswork
explicitly ("primary color inferred from CTA button, not from a brand guide").

### Step 5 — Apply via Document Layout wizard

With confirmed values:

1. Upload logo and favicon to `res.company` (*Settings → Companies → Logo / Favicon*).
2. Open *Settings → General Settings → Companies → Configure Document Layout* and set: `report_layout`, `primary_color`, `secondary_color`, `font`, `report_footer`, `paperformat_id`.
3. On v19: also set `email_primary_color` / `email_secondary_color` explicitly — they do not auto-follow `primary_color` / `secondary_color` anymore.
4. For website: *Website → Configuration → Website → Theme → Colors* and apply the same primary/secondary.
5. Verify PDF: *Sales → Quotations → any record → Print → Quotation* and confirm colors render. Also open a portal page (`/my`) logged in as the customer test user.

### Step 6 — Generic defaults (when no reference exists AND user can't provide one)

Only when explicitly instructed to proceed without reference:

- Primary: `#714B67` (Odoo default — tell user this is Odoo's own brand, usually not what they want)
- Font: `Roboto`
- Layout: `clean`
- Logo: Odoo placeholder (recommend replacing before showing demo to customer)

Always surface this in your response: *"Pokračujem s Odoo defaultmi, lebo
nemáme referenciu — pred prezentáciou zákazníkovi ešte raz prejdime brand."*

---

## 15. What's out of scope

- QWeb syntax mechanics and rendering internals — **odoo-qweb** owns this
- wkhtmltopdf install/config on on-prem — DevOps, not this skill
- Custom OWL widget JS authoring — see Odoo developer documentation
- Accessibility audits — not opinionated here; follow normal web a11y guidance
- Performance tuning of asset bundles (minification, splitting) — Odoo handles this automatically; customize via `xml_node` types if needed
