# Modul Accounting — Odoo 18/19

Funkčná referencia pre fakturáciu, dane, reporty a multi-company účtovníctvo.
Ukážky server action kódu overené proti Odoo 19.0 SaaS.

---

## Invoicing Workflow

### Typy dokumentov (`account.move.move_type`)

| Typ | `move_type` | Smer |
|---|---|---|
| Customer Invoice | `out_invoice` | AR+ |
| Customer Credit Note | `out_refund` | AR- |
| Vendor Bill | `in_invoice` | AP+ |
| Vendor Refund | `in_refund` | AP- |
| Entry (journal entry) | `entry` | GL |

### Životný cyklus

1. Vytvoriť v `draft` — editujte voľne, dane sa prepočítavajú automaticky.
2. Post (`action_post()`) → state sa stáva `posted`, priradí sa sequence number, uzamkne sa.
3. Register Payment → vytvorí `account.payment` + zreconciluje s move lines.
4. Voliteľné: Reset to Draft (*Actions → Reset to Draft*) ak to journal dovolí.

### Server Action — post faktúry pri označení ako zaplatená

Použite z Automated Action na `account.move`, Trigger: On Update poľa `payment_state`.

```python
for invoice in records:
    if invoice.state == 'draft' and invoice.payment_state == 'paid':
        invoice.action_post()
```

Poznámka: zabudovaný flow Odoo postuje faktúru pred platbou, nie po nej. Scenár
vyššie je pre netypické workflow, kde sú faktúry draftované po platbe.

---

## Dane

Menu: *Accounting → Configuration → Taxes*

Kľúčové atribúty dane:
- `amount_type`: `percent` / `fixed` / `group` / `division`
- `type_tax_use`: `sale` / `purchase` / `none`
- `price_include`: daň zahrnutá v cene produktu (B2C) vs pripočítaná (B2B)
- `tax_group_id`: kontroluje, ako sa dane stackujú v sekcii reportu

### Odkiaľ pochádzajú dane na invoice line

Poradie rozhodnutia (prvá zhoda vyhráva):
1. Mapovanie fiscal position (`partner.property_account_position_id`) — konvertuje defaultnú daň produktu na inú daň podľa regiónu/typu zákazníka.
2. Default produktu (`product.taxes_id` pre sales, `supplier_taxes_id` pre purchases).
3. Company fallback (zvyčajne žiadny).

### Fiscal Position — auto-priradenie podľa krajiny

Príklad Automated Action na `account.move`, Trigger: On Create, Model filter: `move_type in ('out_invoice', 'out_refund')`.

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

`onchange_invoice_line_ids()` (referencované v staršom materiáli) v v17+ **neexistuje**.
Priradenie `fiscal_position_id` cez ORM write() spúšťa
`_onchange_fiscal_position_id` vo form-kontexte; pre batch updates na uložených
záznamoch použite `invoice._recompute_dynamic_lines(recompute_all_taxes=True)`, ak
treba dane forcnúť.

---

## Finančné reporty

Menu: *Accounting → Reporting*

Zabudované reporty:
- **Balance Sheet** (`account.financial.html.report`, xmlid sa líši podľa lokalizácie)
- **Profit and Loss** (rovnaké)
- **Cash Flow Statement**
- **General Ledger**, **Trial Balance**, **Partner Ledger**, **Aged Receivable/Payable**
- **Tax Report** — špecifický pre lokalizáciu

Daňové reporty špecifické pre krajinu žijú pod *Configuration → Fiscal Localizations*
a závisia od nainštalovaného modulu `l10n_xx`.

### Generovanie PDF reportu programovo

Odoo 19 API je `_render_qweb_pdf(report_ref, res_ids=None, data=None)` na
modeli `ir.actions.report`.

```python
report = env.ref('account_reports.action_account_report_bs', raise_if_not_found=False)
# Or pass the XML ID string directly:
pdf_bytes, content_type = env['ir.actions.report']._render_qweb_pdf(
    'account_reports.action_account_report_bs',
    res_ids=[env.company.id],
)
# content_type == 'pdf'
```

Pre web linky funguje `/web#action=...&active_ids=...` na otvorenie reportu v
UI; priamy PDF download vyžaduje `/report/pdf/<report_xmlid>/<ids>` s
autentifikovanou session (API keys na bearer endpointe nefungujú — pozri
odoo-api skill).

---

## Multi-Company a konsolidácia

### Základy nastavenia

- *Settings → Users & Companies → Companies* — vytvorte subsidiaries.
- Každá company vlastní svoje journals, dane, CoA a fiscal localization.
- Používatelia dostávajú prístup cez `res.users.company_ids` (M2M) a default `company_id`.

### Inter-company transakcie

Zapnuté per company: *Settings → General Settings → Companies → Inter-Company Transactions*.
Možnosti: *Synchronize Invoices*, *Synchronize Sale/Purchase Orders*.

Keď Company A postne out_invoice na Company B (interný partner), Odoo
automaticky vytvorí zrkadlenú in_invoice v Company B.

### Multi-company doménové vzory (pre record rules)

```python
# Standard: records own the company
[('company_id', 'in', user.company_ids.ids)]

# Records shared across companies (global records + per-company records)
['|', ('company_id', '=', False), ('company_id', 'in', user.company_ids.ids)]
```

---

## Bežné účtovnícke problémy

| Symptóm | Príčina | Riešenie |
|---|---|---|
| "Journal missing" pri post | Žiadny default journal pre company/move_type | Nastavte v *Accounting → Configuration → Journals* |
| Nemôžem post do minulého obdobia | Obdobie zamknuté | *Accounting → Actions → Lock Dates* — upravte alebo použite novší dátum |
| Daň = 0 na riadku | Žiadna daň na produkte alebo fiscal position ju vyblanking | Skontrolujte `product.taxes_id` + `partner.property_account_position_id` |
| Multi-currency exchange diff | FX rate v deň invoice vs deň platby | Postnite exchange difference journal entry (automatické, ak je nakonfigurovaný FX journal) |
| Credit note na postnutej faktúre | Nemôžem editovať postnutý dokument | *Actions → Reverse / Credit Note* |
| Duplicitné sequence number | Dve companies zdieľajú journal | Dajte každej company vlastný journal so sequence špecifickou pre company |

---

## Ďalšie zdroje

- Accounting docs: https://www.odoo.com/documentation/19.0/applications/finance/accounting.html
- Fiscal localizations: https://www.odoo.com/documentation/19.0/applications/finance/fiscal_localizations.html
