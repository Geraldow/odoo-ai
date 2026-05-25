# Accounting Module — Odoo 18/19

Functional reference for invoicing, taxes, reports, and multi-company accounting.
Server-action code samples verified against Odoo 19.0 SaaS.

---

## Invoicing Workflow

### Document types (`account.move.move_type`)

| Type | `move_type` | Direction |
|---|---|---|
| Customer Invoice | `out_invoice` | AR+ |
| Customer Credit Note | `out_refund` | AR- |
| Vendor Bill | `in_invoice` | AP+ |
| Vendor Refund | `in_refund` | AP- |
| Entry (journal entry) | `entry` | GL |

### Lifecycle

1. Create in `draft` — edit freely, taxes recompute automatically.
2. Post (`action_post()`) → state becomes `posted`, sequence number assigned, locked.
3. Register Payment → creates `account.payment` + reconciles with the move lines.
4. Optional: Reset to Draft (*Actions → Reset to Draft*) if the journal allows it.

### Server Action — post invoice when marked paid

Use from an Automated Action on `account.move`, Trigger: On Update of `payment_state`.

```python
for invoice in records:
    if invoice.state == 'draft' and invoice.payment_state == 'paid':
        invoice.action_post()
```

Note: the built-in Odoo flow posts the invoice before payment, not after. The
scenario above is for unusual workflows where invoices are drafted after payment.

---

## Taxes

Menu: *Accounting → Configuration → Taxes*

Key tax attributes:
- `amount_type`: `percent` / `fixed` / `group` / `division`
- `type_tax_use`: `sale` / `purchase` / `none`
- `price_include`: tax included in product price (B2C) vs added (B2B)
- `tax_group_id`: controls how taxes stack in the report section

### Where taxes come from on an invoice line

Resolution order (first match wins):
1. Fiscal position mapping (`partner.property_account_position_id`) — converts a product's default tax into a different tax per customer region/type.
2. Product default (`product.taxes_id` for sales, `supplier_taxes_id` for purchases).
3. Company fallback (usually none).

### Fiscal Position — auto-assign by country

Example Automated Action on `account.move`, Trigger: On Create, Model filter: `move_type in ('out_invoice', 'out_refund')`.

```python
for invoice in records:
    country = invoice.partner_id.country_id
    if not country:
        continue
    fp = env['account.fiscal.position'].sudo().search([
        ('country_id', '=', country.id),
        ('company_id', '=', invoice.company_id.id),
    ], limit=1)
    if fp and invoice.fiscal_position_id != fp:
        invoice.fiscal_position_id = fp
        # Write triggers the onchange chain that recomputes taxes on lines
        # because fiscal_position_id has an @api.onchange on account.move.
        # For already-posted invoices you cannot change fiscal_position_id —
        # reset to draft first.
```

`onchange_invoice_line_ids()` (referenced in older material) does **not** exist in
v17+. Assigning `fiscal_position_id` through ORM write() triggers
`_onchange_fiscal_position_id` in the form-context; for batch updates on saved
records use `invoice._recompute_dynamic_lines(recompute_all_taxes=True)` if
taxes need forcing.

---

## Financial Reports

Menu: *Accounting → Reporting*

Built-in reports:
- **Balance Sheet** (`account.financial.html.report`, xmlid varies by localization)
- **Profit and Loss** (same)
- **Cash Flow Statement**
- **General Ledger**, **Trial Balance**, **Partner Ledger**, **Aged Receivable/Payable**
- **Tax Report** — localization-specific

Country-specific tax reports live under *Configuration → Fiscal Localizations*
and depend on the installed `l10n_xx` module.

### Generating a report PDF programmatically

Odoo 19 API is `_render_qweb_pdf(report_ref, res_ids=None, data=None)` on the
`ir.actions.report` model.

```python
report = env.ref('account_reports.action_account_report_bs', raise_if_not_found=False)
# Or pass the XML ID string directly:
pdf_bytes, content_type = env['ir.actions.report']._render_qweb_pdf(
    'account_reports.action_account_report_bs',
    res_ids=[env.company.id],
)
# content_type == 'pdf'
```

For web links, `/web#action=...&active_ids=...` works for opening the report in
the UI; direct PDF download requires `/report/pdf/<report_xmlid>/<ids>` with an
authenticated session (API keys on the bearer endpoint will not work — see
odoo-api skill).

---

## Multi-Company & Consolidation

### Setup essentials

- *Settings → Users & Companies → Companies* — create subsidiaries.
- Each company owns its own journals, taxes, CoA, and fiscal localization.
- Users get access via `res.users.company_ids` (M2M) and a default `company_id`.

### Inter-company transactions

Enabled per company: *Settings → General Settings → Companies → Inter-Company Transactions*.
Options: *Synchronize Invoices*, *Synchronize Sale/Purchase Orders*.

When Company A posts an out_invoice to Company B (internal partner), Odoo
creates the mirrored in_invoice in Company B automatically.

### Multi-company domain patterns (for record rules)

```python
# Standard: records own the company
[('company_id', 'in', user.company_ids.ids)]

# Records shared across companies (global records + per-company records)
['|', ('company_id', '=', False), ('company_id', 'in', user.company_ids.ids)]
```

---

## Common accounting issues

| Symptom | Cause | Fix |
|---|---|---|
| "Journal missing" on post | No default journal for the company/move_type | Set in *Accounting → Configuration → Journals* |
| Can't post into prior period | Period locked | *Accounting → Actions → Lock Dates* — adjust or use a newer date |
| Tax = 0 on line | No tax on product, or fiscal position blanks it | Check `product.taxes_id` + `partner.property_account_position_id` |
| Multi-currency exchange diff | FX rate at invoice date vs payment date | Post exchange difference journal entry (automatic if FX journal is configured) |
| Credit note on posted invoice | Can't edit posted doc | *Actions → Reverse / Credit Note* |
| Duplicate sequence number | Two companies sharing a journal | Give each company its own journal with company-specific sequence |

---

## Further reading

- Accounting docs: https://www.odoo.com/documentation/19.0/applications/finance/accounting.html
- Fiscal localizations: https://www.odoo.com/documentation/19.0/applications/finance/fiscal_localizations.html
