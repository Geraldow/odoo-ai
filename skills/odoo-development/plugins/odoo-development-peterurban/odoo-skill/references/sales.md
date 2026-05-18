# Sales Module — Odoo 18/19

Functional reference for the Sales app: invoicing policy, quotation lifecycle,
common configuration scenarios. Server-action code samples in this file are
safe_eval-compatible and verified against Odoo 19.0 SaaS.

---

## Invoicing Policy

### Setup

Menu: *Sales → Configuration → Settings → Invoicing → Invoicing Policy*

Two module-level options:

- **Invoice what is ordered** — invoice becomes available as soon as the SO is confirmed
- **Invoice what is delivered** — invoice becomes available only after the related picking is validated (qty_delivered updates)

### Product-level setting

Each product has its own policy: *Product form → Invoicing tab → Invoicing Policy*.
The module-level setting only applies to **new** products. Existing products keep
their current policy — update them manually if needed.

### Caveat: Automatic Invoice

If *Automatic Invoice* is enabled (Settings → Invoicing), it requires **ordered**
policy. The two options are mutually exclusive.

### Typical choices

| Scenario | Policy | Why |
|---|---|---|
| B2B with deliveries | delivered | Revenue recognition follows the shipment |
| B2C webshop | ordered | Invoice right after payment |
| Service with timesheets | delivered (timesheet-based) | Quantities come from `account.analytic.line` |
| Milestone-based services | delivered (manual) | Sales rep marks qty_delivered per milestone |

---

## Quotation → Sales Order → Invoice

### State machine (`sale.order.state`)

1. **`draft`** — Quotation. No inventory/accounting impact.
2. **`sent`** — Quotation sent to customer. Still no backend impact.
3. **`sale`** — Confirmed. Stock reservations + delivery pickings created. Invoice
   eligibility depends on policy.
4. **`done`** (optional) — Locked. Enabled via Settings → "Lock Confirmed Orders".
5. **`cancel`** — Cancelled.

### Delivery flow

Confirming a SO creates a `stock.picking` (outgoing) linked via `picking_ids`.
Validating the picking (`button_validate`) updates `qty_delivered` on each line.
Under the **delivered** policy, the *Create Invoice* button only appears once
`qty_delivered > qty_invoiced` on at least one line.

### Invoice creation

- UI button → calls `sale.order._create_invoices()` which returns one or more
  `account.move` records in draft state.
- To post immediately, follow with `action_post()` on the returned moves.
- Status fields on SO: `invoice_status` (`no` / `to invoice` / `invoiced` /
  `upselling`), `invoice_ids` (M2M to posted invoices).

---

## Down Payments (B2B prepayment scenario)

Menu: *Product form → Invoicing → "Down Payment"* (auto-created by Odoo; do not create manually).

1. Confirm the SO.
2. On the SO, click *Create Invoice* → choose *Down payment (percentage)* or
   *Down payment (fixed amount)*.
3. Post the down-payment invoice and register payment.
4. After delivery, click *Create Invoice* again → choose *Regular invoice*.
   Odoo automatically subtracts posted down payments from the final amount.

Key fields:
- `sale.order.line.is_downpayment` (computed, read-only)
- `account.move.line.sale_line_ids` — traces the invoice line back to SO lines

---

## Make-to-Order (MTO)

MTO is controlled by **routes**, not a single field on the product.

Setup:
1. *Inventory → Configuration → Settings* → enable *Multi-Step Routes*.
2. *Product form → Purchase/Inventory tab → Routes* — check **Replenish on Order (MTO)**.
3. If manufactured, also check **Manufacture**.
4. Optionally enable the route at product-category or warehouse level.

On SO confirmation, Odoo creates the downstream document (PO, MO) automatically
based on the route chain. Traceability: `stock.move.sale_line_id` → SO line.

---

## Partial / Staged Deliveries

Use case: one SO, multiple scheduled shipments.

Recommended setup:
- **Invoicing policy = delivered** (avoids invoicing undelivered qty)
- Split the picking manually: open the delivery, change *Done Qty* to the
  partial amount, validate. Odoo prompts to *Create Backorder* for the rest.
- Each validated picking is a separate invoice event. The SO can issue multiple
  `account.move` records across the lifecycle.

Gotcha: with policy = *ordered*, the full invoice is available at confirmation
regardless of partial deliveries.

---

## Server Action — Auto-confirm SO based on a custom flag

Scenario: mark a quotation with a Studio boolean `x_studio_auto_confirm`; when
set, confirm automatically via Automated Action.

Create: *Settings → Technical → Automated Actions → New*
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

No `display_notification` needed — automated actions run without UI feedback.
If you want a toast, wire a manual Server Action on a button instead.

---

## Common SO issues

| Symptom | Cause | Fix |
|---|---|---|
| *Confirm* button inactive | SO not in `draft`/`sent` | Check `state` |
| No delivery picking created | Product type = `service` | Services don't create stock moves by default |
| Invoice qty = 0 under "delivered" | Picking not validated | Validate picking, `qty_delivered` updates |
| Price = 0 on line | No pricelist or wrong partner_id | Check `partner_id.property_product_pricelist` |
| No tax on invoice | Product has no tax, or fiscal position overrides it | Check `product.taxes_id` and `partner.property_account_position_id` |
| Email not sent | No template bound / `smtp` not configured | *Technical → Email → Templates* |

---

## Further reading

- Invoicing: https://www.odoo.com/documentation/19.0/applications/finance/accounting/customer_invoices.html
- Sales basics: https://www.odoo.com/documentation/19.0/applications/sales/sales.html
- Routes / MTO: https://www.odoo.com/documentation/19.0/applications/inventory_and_mrp/inventory/warehouses_storage/replenishment.html
