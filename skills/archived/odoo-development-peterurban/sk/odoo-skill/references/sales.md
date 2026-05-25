# Modul Sales — Odoo 18/19

Funkčná referencia pre aplikáciu Sales: invoicing policy, životný cyklus ponuky,
bežné konfiguračné scenáre. Ukážky server action kódu v tomto súbore sú
safe_eval-kompatibilné a overené proti Odoo 19.0 SaaS.

---

## Invoicing Policy

### Nastavenie

Menu: *Sales → Configuration → Settings → Invoicing → Invoicing Policy*

Dve module-level možnosti:

- **Invoice what is ordered** — faktúra je dostupná hneď po potvrdení SO
- **Invoice what is delivered** — faktúra je dostupná až po validácii súvisiaceho pickingu (aktualizuje sa qty_delivered)

### Nastavenie na úrovni produktu

Každý produkt má svoju vlastnú policy: *Product form → Invoicing tab → Invoicing Policy*.
Module-level nastavenie sa aplikuje iba na **nové** produkty. Existujúce produkty si zachovajú
svoju aktuálnu policy — v prípade potreby ich aktualizujte manuálne.

### Upozornenie: Automatic Invoice

Ak je *Automatic Invoice* zapnutá (Settings → Invoicing), vyžaduje policy **ordered**.
Tieto dve možnosti sú vzájomne výlučné.

### Typické voľby

| Scenár | Policy | Prečo |
|---|---|---|
| B2B s dodávkami | delivered | Uznanie výnosov nasleduje expedíciu |
| B2C eshop | ordered | Faktúra hneď po platbe |
| Služba s timesheetmi | delivered (timesheet-based) | Množstvá pochádzajú z `account.analytic.line` |
| Služby podľa míľnikov | delivered (manual) | Sales rep manuálne označuje qty_delivered na míľnik |

---

## Quotation → Sales Order → Invoice

### State machine (`sale.order.state`)

1. **`draft`** — Ponuka. Žiadny dopad na sklad/účtovníctvo.
2. **`sent`** — Ponuka odoslaná zákazníkovi. Stále žiadny backend dopad.
3. **`sale`** — Potvrdená. Vytvárajú sa stock rezervácie + delivery pickingy. Invoice
   eligibility závisí od policy.
4. **`done`** (voliteľné) — Zamknuté. Zapína sa cez Settings → "Lock Confirmed Orders".
5. **`cancel`** — Zrušené.

### Delivery flow

Potvrdením SO sa vytvorí `stock.picking` (outgoing) napojený cez `picking_ids`.
Validácia pickingu (`button_validate`) aktualizuje `qty_delivered` na každom riadku.
Pri policy **delivered** sa tlačidlo *Create Invoice* objaví iba vtedy, keď je
`qty_delivered > qty_invoiced` aspoň na jednom riadku.

### Vytvorenie faktúry

- UI tlačidlo → volá `sale.order._create_invoices()`, ktoré vracia jeden alebo viac
  záznamov `account.move` v stave draft.
- Na okamžité posting pridajte `action_post()` na vrátené moves.
- Status polia na SO: `invoice_status` (`no` / `to invoice` / `invoiced` /
  `upselling`), `invoice_ids` (M2M na posted faktúry).

---

## Down Payments (B2B scenár preddavku)

Menu: *Product form → Invoicing → "Down Payment"* (auto-vytvorený Odoom; nevytvárajte manuálne).

1. Potvrďte SO.
2. Na SO kliknite *Create Invoice* → zvoľte *Down payment (percentage)* alebo
   *Down payment (fixed amount)*.
3. Postnite down-payment faktúru a zaregistrujte platbu.
4. Po dodávke kliknite znova *Create Invoice* → zvoľte *Regular invoice*.
   Odoo automaticky odpočíta postnuté down payments z finálnej sumy.

Kľúčové polia:
- `sale.order.line.is_downpayment` (computed, read-only)
- `account.move.line.sale_line_ids` — trasuje invoice line späť na SO lines

---

## Make-to-Order (MTO)

MTO je kontrolované **routami**, nie jedným poľom na produkte.

Nastavenie:
1. *Inventory → Configuration → Settings* → zapnite *Multi-Step Routes*.
2. *Product form → Purchase/Inventory tab → Routes* — zaškrtnite **Replenish on Order (MTO)**.
3. Ak je vyrábaný, zaškrtnite aj **Manufacture**.
4. Voliteľne zapnite route na úrovni kategórie produktu alebo warehouse.

Pri potvrdení SO Odoo automaticky vytvorí downstream dokument (PO, MO)
na základe route chain. Traceability: `stock.move.sale_line_id` → SO line.

---

## Čiastočné / etapové dodávky

Použitie: jeden SO, viaceré plánované expedície.

Odporúčané nastavenie:
- **Invoicing policy = delivered** (vyhne sa fakturácii nedodaného qty)
- Rozdeľte picking manuálne: otvorte dodávku, zmeňte *Done Qty* na
  čiastočnú sumu, validujte. Odoo vyzve *Create Backorder* pre zvyšok.
- Každý validovaný picking je samostatná invoice event. SO môže vystaviť viaceré
  `account.move` záznamy naprieč životným cyklom.

Úskalie: pri policy = *ordered* je plná faktúra dostupná pri potvrdení
bez ohľadu na čiastočné dodávky.

---

## Server Action — Auto-confirm SO podľa vlastného flagu

Scenár: označte quotation Studio booleanom `x_studio_auto_confirm`; keď
je nastavený, potvrdiť automaticky cez Automated Action.

Vytvorte: *Settings → Technical → Automated Actions → New*
- Model: Sales Order
- Trigger: On Update → Trigger Fields: `x_studio_auto_confirm`
- Apply on: `[('x_studio_auto_confirm', '=', True), ('state', '=', 'draft')]`
- Action: Execute Code

```python
# records = SOs whose x_studio_auto_confirm just flipped to True
for order in records:
    if order.state == 'draft':
        order.action_confirm()
```

Nie je potrebný `display_notification` — automated actions bežia bez UI feedbacku.
Ak chcete toast, napojte manuálnu Server Action na tlačidlo.

---

## Bežné SO problémy

| Symptóm | Príčina | Riešenie |
|---|---|---|
| Tlačidlo *Confirm* neaktívne | SO nie je v `draft`/`sent` | Skontrolujte `state` |
| Nevytvorí sa delivery picking | Product type = `service` | Služby štandardne nevytvárajú stock moves |
| Invoice qty = 0 pri "delivered" | Picking nebol validovaný | Validujte picking, aktualizuje sa `qty_delivered` |
| Price = 0 na riadku | Žiadny pricelist alebo zlý partner_id | Skontrolujte `partner_id.property_product_pricelist` |
| Žiadna daň na faktúre | Produkt nemá daň alebo fiscal position ju overrideuje | Skontrolujte `product.taxes_id` a `partner.property_account_position_id` |
| Email nebol odoslaný | Nie je bindnutá šablóna / `smtp` nie je nakonfigurované | *Technical → Email → Templates* |

---

## Ďalšie zdroje

- Invoicing: https://www.odoo.com/documentation/19.0/applications/finance/accounting/customer_invoices.html
- Sales basics: https://www.odoo.com/documentation/19.0/applications/sales/sales.html
- Routes / MTO: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/replenishment.html
