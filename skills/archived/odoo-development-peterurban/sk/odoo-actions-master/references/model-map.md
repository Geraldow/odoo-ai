# Mapa vzťahov Odoo modelov — cross-module FK diagram

## Obsah

1. [Cross-module flow diagramy](#cross-module-flow-diagramy)
2. [Sales flow](#sales-flow)
3. [Purchase flow](#purchase-flow)
4. [Inventory/Warehouse](#inventorywarehouse)
5. [Účtovníctvo](#uctovnictvo)
6. [Manufacturing](#manufacturing)
7. [Projekty a timesheety](#projekty-a-timesheety)
8. [CRM](#crm)
9. [HR](#hr)
10. [Core/Base](#corebase)
11. [Infraštruktúra/systém](#infrastrukturasystem)
12. [Produkty](#produkty)

---

## Cross-module flow diagramy

### Sales → Delivery → Invoice (kompletný tok)

```
sale.order
  │
  ├─ partner_id ──────→ res.partner
  ├─ user_id ─────────→ res.users
  ├─ company_id ──────→ res.company
  ├─ currency_id ─────→ res.currency
  │
  ├─ order_line ──────→ sale.order.line[]
  │     ├─ product_id ──→ product.product
  │     ├─ invoice_lines → account.move.line[] (M2M)
  │     └─ sale_line_id ←── stock.move (reverse FK)
  │
  ├─ picking_ids ─────→ stock.picking[] (deliveries)
  │     ├─ sale_id ────→ sale.order (reverse FK)
  │     └─ move_ids ──→ stock.move[]
  │           └─ sale_line_id → sale.order.line
  │
  └─ invoice_ids ─────→ account.move[] (M2M via sale_order_invoice_rel)
        ├─ move_type = 'out_invoice'
        └─ line_ids → account.move.line[]
              └─ sale_line_ids → sale.order.line[] (M2M)
```

### Purchase → Receipt → Bill

```
purchase.order
  │
  ├─ partner_id ──────→ res.partner (vendor)
  ├─ order_line ──────→ purchase.order.line[]
  │     └─ product_id → product.product
  │
  ├─ picking_ids ─────→ stock.picking[] (receipts)
  │     ├─ purchase_id → purchase.order (reverse FK)
  │     └─ move_ids ──→ stock.move[]
  │           └─ purchase_line_id → purchase.order.line
  │
  └─ invoice_ids ─────→ account.move[] (vendor bills)
        ├─ move_type = 'in_invoice'
        └─ line_ids → account.move.line[]
              └─ purchase_line_id → purchase.order.line
```

### Manufacturing → spotreba a výstup zásob

```
mrp.production
  │
  ├─ product_id ──────→ product.product (finished product)
  ├─ bom_id ──────────→ mrp.bom
  │     └─ bom_line_ids → mrp.bom.line[]
  │           └─ product_id → product.product (component)
  │
  ├─ move_raw_ids ────→ stock.move[] (component consumption)
  │     └─ raw_material_production_id → mrp.production
  │
  ├─ move_finished_ids → stock.move[] (finished output)
  │
  └─ workorder_ids ───→ mrp.workorder[]
        ├─ workcenter_id → mrp.workcenter
        └─ operation_id → mrp.routing.workcenter
```

### HR → Users → Partners

```
res.partner (base contact)
  │
  ├─ _inherits ←── res.users (delegation: user IS a partner)
  │     ├─ partner_id → res.partner
  │     ├─ groups_id → res.groups[] (M2M)
  │     ├─ company_id → res.company
  │     └─ company_ids → res.company[] (M2M)
  │
  └─ ←── hr.employee
        ├─ user_id → res.users (optional, for system login)
        ├─ address_home_id → res.partner (private contact)
        ├─ department_id → hr.department
        ├─ job_id → hr.job
        ├─ contract_ids → hr.contract[]
        └─ resource_id → resource.resource
```

---

## Sales flow

### sale.order

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | SO reference (SO0001) |
| partner_id | M2O | res.partner | Zákazník |
| partner_invoice_id | M2O | res.partner | Fakturačná adresa |
| partner_shipping_id | M2O | res.partner | Doručovacia adresa |
| order_line | O2M | sale.order.line | Riadky objednávky |
| picking_ids | O2M | stock.picking | Deliveries (reverse: sale_id) |
| invoice_ids | M2M | account.move | Faktúry (via sale_order_invoice_rel) |
| user_id | M2O | res.users | Obchodník |
| team_id | M2O | crm.team | Sales team |
| company_id | M2O | res.company | Spoločnosť |
| currency_id | M2O | res.currency | Mena |
| pricelist_id | M2O | product.pricelist | Cenník |
| state | Selection | — | draft/sent/sale/done/cancel |
| date_order | Datetime | — | Dátum objednávky |
| amount_untaxed | Monetary | — | Computed: suma bez DPH |
| amount_tax | Monetary | — | Computed: DPH |
| amount_total | Monetary | — | Computed: celková suma |
| invoice_status | Selection | — | upselling/invoiced/to invoice/no |
| delivery_count | Integer | — | Computed: počet deliveries |

### sale.order.line

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| order_id | M2O | sale.order | Parent objednávka |
| product_id | M2O | product.product | Produkt |
| product_template_id | M2O | product.template | Template produktu |
| product_uom | M2O | uom.uom | Merná jednotka |
| product_uom_qty | Float | — | Objednané množstvo |
| qty_delivered | Float | — | Computed: dodané |
| qty_invoiced | Float | — | Computed: fakturované |
| qty_to_invoice | Float | — | Computed: na fakturáciu |
| price_unit | Float | — | Jednotková cena |
| discount | Float | — | Zľava % |
| price_subtotal | Monetary | — | Computed: suma riadku |
| invoice_lines | M2M | account.move.line | Prepojené fakturačné riadky |
| invoice_status | Selection | — | upselling/invoiced/to_invoice/no |

---

## Purchase flow

### purchase.order

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | PO reference |
| partner_id | M2O | res.partner | Dodávateľ |
| order_line | O2M | purchase.order.line | Riadky PO |
| picking_ids | O2M | stock.picking | Príjemky (reverse: purchase_id) |
| invoice_ids | M2M | account.move | Vendor bills |
| state | Selection | — | draft/sent/to approve/purchase/done/cancel |
| date_order | Datetime | — | Dátum objednávky |
| currency_id | M2O | res.currency | Mena |
| company_id | M2O | res.company | Spoločnosť |

### purchase.order.line

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| order_id | M2O | purchase.order | Parent PO |
| product_id | M2O | product.product | Produkt |
| product_qty | Float | — | Objednané množstvo |
| qty_received | Float | — | Prijaté množstvo |
| qty_invoiced | Float | — | Fakturované množstvo |
| price_unit | Float | — | Jednotková cena |
| product_uom | M2O | uom.uom | Merná jednotka |

---

## Inventory/Warehouse

### stock.warehouse

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov skladu |
| code | Char | — | Short code (WH, WH2) |
| lot_stock_id | M2O | stock.location | Hlavná skladová lokácia |
| in_type_id | M2O | stock.picking.type | Typ príjemky |
| out_type_id | M2O | stock.picking.type | Typ výdajky |
| int_type_id | M2O | stock.picking.type | Interný presun |
| company_id | M2O | res.company | Spoločnosť |

### stock.location

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov lokácie |
| location_id | M2O | stock.location | Parent lokácia (hierarchia) |
| warehouse_id | M2O | stock.warehouse | Prislúchajúci sklad |
| usage | Selection | — | internal/customer/vendor/inventory/view/production/transit |
| quant_ids | O2M | stock.quant | Zásoby na lokácii |
| company_id | M2O | res.company | Spoločnosť |

### stock.picking

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Reference (WH/OUT/00001) |
| picking_type_id | M2O | stock.picking.type | Typ operácie |
| move_ids | O2M | stock.move | Pohyby v tomto transfere |
| sale_id | M2O | sale.order | Zdrojová SO |
| purchase_id | M2O | purchase.order | Zdrojová PO |
| origin | Char | — | Zdrojový dokument (text) |
| partner_id | M2O | res.partner | Partner |
| location_id | M2O | stock.location | Zdrojová lokácia |
| location_dest_id | M2O | stock.location | Cieľová lokácia |
| state | Selection | — | draft/waiting/confirmed/assigned/done/cancel |
| scheduled_date | Datetime | — | Plánovaný dátum |
| date_done | Datetime | — | Dátum dokončenia |

### stock.move

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| picking_id | M2O | stock.picking | Parent transfer |
| product_id | M2O | product.product | Produkt |
| product_uom_qty | Float | — | Požadované množstvo |
| quantity | Float | — | Skutočné množstvo (v19: quantity namiesto quantity_done) |
| sale_line_id | M2O | sale.order.line | SO riadok (reverse trace) |
| purchase_line_id | M2O | purchase.order.line | PO riadok (reverse trace) |
| raw_material_production_id | M2O | mrp.production | Výrobný príkaz (spotreba) |
| production_id | M2O | mrp.production | Výrobný príkaz (výstup) |
| location_id | M2O | stock.location | Zdroj |
| location_dest_id | M2O | stock.location | Cieľ |
| move_dest_ids | M2M | stock.move | Nadväzujúce pohyby (chain) |
| state | Selection | — | draft/confirmed/assigned/done/cancel |

### stock.move.line (detailný pohyb — lot/serial level)

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| move_id | M2O | stock.move | Parent pohyb |
| product_id | M2O | product.product | Produkt |
| lot_id | M2O | stock.lot | Lot/sériové číslo |
| location_id | M2O | stock.location | Zdroj |
| location_dest_id | M2O | stock.location | Cieľ |
| qty_done | Float | — | Spracované množstvo |
| package_id | M2O | stock.quant.package | Balenie |
| owner_id | M2O | res.partner | Vlastník zásob (consignment) |

### stock.quant (aktuálne zásoby)

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| product_id | M2O | product.product | Produkt |
| location_id | M2O | stock.location | Lokácia |
| lot_id | M2O | stock.lot | Lot/serial |
| quantity | Float | — | Na sklade |
| reserved_quantity | Float | — | Rezervované |
| owner_id | M2O | res.partner | Vlastník |
| package_id | M2O | stock.quant.package | Balenie |
| in_date | Datetime | — | Dátum naskladnenia |

### stock.route a stock.rule

| Model | Pole | Typ | Cieľ |
|---|---|---|---|
| stock.route | rule_ids | O2M | stock.rule |
| stock.route | warehouse_ids | M2M | stock.warehouse |
| stock.rule | route_id | M2O | stock.route |
| stock.rule | picking_type_id | M2O | stock.picking.type |
| stock.rule | location_src_id | M2O | stock.location |
| stock.rule | location_dest_id | M2O | stock.location |
| stock.rule | action | Selection | — (buy/manufacture/pull/push) |

---

## Účtovníctvo

### account.move (Journal Entry / faktúra)

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Číslo dokladu |
| move_type | Selection | — | entry/out_invoice/in_invoice/out_refund/in_refund |
| partner_id | M2O | res.partner | Partner |
| journal_id | M2O | account.journal | Účtovný denník |
| line_ids | O2M | account.move.line | Účtovné riadky |
| invoice_line_ids | O2M | account.move.line | Invoice riadky (filter na line_ids) |
| state | Selection | — | draft/posted/cancel |
| date | Date | — | Dátum účtovania |
| invoice_date | Date | — | Dátum vystavenia faktúry |
| invoice_date_due | Date | — | Splatnosť |
| currency_id | M2O | res.currency | Mena |
| company_id | M2O | res.company | Spoločnosť |
| origin | Char | — | Zdrojový dokument (SO name, PO name) |
| amount_total | Monetary | — | Celková suma |
| amount_residual | Monetary | — | Neuhradený zvyšok |
| payment_state | Selection | — | not_paid/in_payment/paid/partial/reversed |

### account.move.line

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| move_id | M2O | account.move | Parent doklad |
| account_id | M2O | account.account | Účet |
| product_id | M2O | product.product | Produkt |
| partner_id | M2O | res.partner | Partner |
| debit | Monetary | — | Má dať |
| credit | Monetary | — | Dal |
| balance | Monetary | — | Computed: debit - credit |
| price_unit | Float | — | Jednotková cena |
| quantity | Float | — | Množstvo |
| discount | Float | — | Zľava % |
| tax_ids | M2M | account.tax | Dane |
| sale_line_ids | M2M | sale.order.line | SO riadky |
| purchase_line_id | M2O | purchase.order.line | PO riadok |

### account.payment

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| partner_id | M2O | res.partner | Partner |
| partner_type | Selection | — | customer/supplier |
| journal_id | M2O | account.journal | Denník |
| amount | Monetary | — | Suma platby |
| payment_date | Date | — | Dátum platby |
| move_id | M2O | account.move | Vytvorený journal entry |
| state | Selection | — | draft/posted/sent/reconciled/cancelled |
| currency_id | M2O | res.currency | Mena |

### account.journal

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov denníka |
| code | Char | — | Prefix (1-5 znakov) |
| type | Selection | — | sale/purchase/general/cash/bank |
| company_id | M2O | res.company | Spoločnosť |

### account.account

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov účtu |
| code | Char | — | Kód účtu |
| account_type | Selection | — | asset/liability/equity/income/expense/... |
| reconcile | Boolean | — | Umožňuje párovanie |
| company_id | M2O | res.company | Spoločnosť |

### account.tax

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov dane |
| type_tax_use | Selection | — | sale/purchase/none |
| amount | Float | — | Sadzba (napr. 20.0) |
| amount_type | Selection | — | percent/fixed/group/division |

---

## Manufacturing

### mrp.production

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | MO reference |
| product_id | M2O | product.product | Vyrábaný produkt |
| product_qty | Float | — | Množstvo na výrobu |
| bom_id | M2O | mrp.bom | Bill of Materials |
| picking_type_id | M2O | stock.picking.type | Typ operácie |
| move_raw_ids | O2M | stock.move | Spotreba komponentov |
| move_finished_ids | O2M | stock.move | Výstup hotových výrobkov |
| workorder_ids | O2M | mrp.workorder | Pracovné príkazy |
| state | Selection | — | confirmed/progress/to_close/done/cancel |
| location_src_id | M2O | stock.location | Zdrojová lokácia |
| location_dest_id | M2O | stock.location | Cieľová lokácia |

### mrp.bom a mrp.bom.line

| Model | Pole | Typ | Cieľ | Popis |
|---|---|---|---|---|
| mrp.bom | product_tmpl_id | M2O | product.template | Template produktu |
| mrp.bom | product_id | M2O | product.product | Variant (optional) |
| mrp.bom | bom_line_ids | O2M | mrp.bom.line | Komponenty |
| mrp.bom | type | Selection | — | normal/phantom (kit) |
| mrp.bom.line | bom_id | M2O | mrp.bom | Parent BOM |
| mrp.bom.line | product_id | M2O | product.product | Komponent |
| mrp.bom.line | product_qty | Float | — | Množstvo komponentu |

### mrp.workorder a mrp.workcenter

| Model | Pole | Typ | Cieľ |
|---|---|---|---|
| mrp.workorder | production_id | M2O | mrp.production |
| mrp.workorder | workcenter_id | M2O | mrp.workcenter |
| mrp.workorder | operation_id | M2O | mrp.routing.workcenter |
| mrp.workorder | state | Selection | — (pending/ready/progress/done/cancel) |
| mrp.workcenter | name | Char | — |
| mrp.workcenter | resource_id | M2O | resource.resource |

---

## Projekty a timesheety

### project.project

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov projektu |
| partner_id | M2O | res.partner | Zákazník |
| task_ids | O2M | project.task | Úlohy |
| sale_order_id | M2O | sale.order | Zdrojová SO |
| user_id | M2O | res.users | Project manager |
| company_id | M2O | res.company | Spoločnosť |

### project.task

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov úlohy |
| project_id | M2O | project.project | Projekt |
| sale_line_id | M2O | sale.order.line | **KĽÚČ: Service SO riadok** |
| sale_order_id | M2O | sale.order | Zdrojová SO |
| user_ids | M2M | res.users | Priradení používatelia |
| partner_id | M2O | res.partner | Zákazník |
| stage_id | M2O | project.task.type | Stav (kanban stage) |
| parent_id | M2O | project.task | Parent úloha (subtasky) |
| child_ids | O2M | project.task | Sub-úlohy |
| timesheet_ids | O2M | account.analytic.line | Timesheet záznamy |

**Prepojenie SO → Task:** `project.task.sale_line_id` je M2O na `sale.order.line`. Keď SO riadok má service produkt s "Create Task" policy, automaticky sa vytvorí task s touto FK.

---

## CRM

### crm.lead

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov opportunity |
| partner_id | M2O | res.partner | Kontakt |
| user_id | M2O | res.users | Obchodník |
| team_id | M2O | crm.team | Sales team |
| stage_id | M2O | crm.stage | Pipeline stage |
| type | Selection | — | lead/opportunity |
| probability | Float | — | Pravdepodobnosť výhry |
| expected_revenue | Monetary | — | Očakávaný príjem |
| order_ids | O2M | sale.order | Vytvorené SO |

### crm.team

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov tímu |
| member_ids | M2M | res.users | Členovia |
| user_id | M2O | res.users | Team leader |

---

## HR

### hr.employee

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Meno zamestnanca |
| user_id | M2O | res.users | Systémový účet (optional) |
| address_home_id | M2O | res.partner | Súkromná adresa |
| department_id | M2O | hr.department | Oddelenie |
| job_id | M2O | hr.job | Pozícia |
| parent_id | M2O | hr.employee | Nadriadený |
| contract_ids | O2M | hr.contract | Zmluvy |
| resource_id | M2O | resource.resource | Resource (pracovný čas) |
| company_id | M2O | res.company | Spoločnosť |

### hr.contract

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| employee_id | M2O | hr.employee | Zamestnanec |
| job_id | M2O | hr.job | Pozícia |
| date_start | Date | — | Začiatok |
| date_end | Date | — | Koniec |
| wage | Monetary | — | Plat |
| state | Selection | — | draft/open/close/cancel |
| resource_calendar_id | M2O | resource.calendar | Pracovný čas |

### hr.leave a hr.leave.type

| Model | Pole | Typ | Cieľ |
|---|---|---|---|
| hr.leave | employee_id | M2O | hr.employee |
| hr.leave | holiday_status_id | M2O | hr.leave.type |
| hr.leave | date_from | Datetime | — |
| hr.leave | date_to | Datetime | — |
| hr.leave | state | Selection | — (draft/confirm/refuse/validate) |
| hr.leave.type | name | Char | — |
| hr.leave.type | requires_allocation | Boolean | — |

---

## Core/Base

### res.partner

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Meno / názov firmy |
| email | Char | — | Email |
| phone | Char | — | Telefón |
| parent_id | M2O | res.partner | Parent firma |
| child_ids | O2M | res.partner | Kontakty firmy |
| is_company | Boolean | — | Je to firma? |
| country_id | M2O | res.country | Krajina |
| state_id | M2O | res.country.state | Štát/región |
| customer_rank | Integer | — | >0 = zákazník |
| supplier_rank | Integer | — | >0 = dodávateľ |
| company_id | M2O | res.company | Spoločnosť |
| vat | Char | — | IČ DPH |

### res.users (inherits res.partner)

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| partner_id | M2O | res.partner | **Delegation inheritance** |
| login | Char | — | Prihlasovacie meno |
| groups_id | M2M | res.groups | Skupiny/role |
| company_id | M2O | res.company | Primárna spoločnosť |
| company_ids | M2M | res.company | Dostupné spoločnosti |

### res.company

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov |
| parent_id | M2O | res.company | Parent firma |
| child_ids | O2M | res.company | Dcérske firmy |
| currency_id | M2O | res.currency | Mena |
| partner_id | M2O | res.partner | Partner záznam firmy |

---

## Infraštruktúra/systém

### ir.model a ir.model.fields

| Model | Pole | Typ | Cieľ | Popis |
|---|---|---|---|---|
| ir.model | model | Char | — | Technický názov (sale.order) |
| ir.model | field_id | O2M | ir.model.fields | Polia modelu |
| ir.model | access_ids | O2M | ir.model.access | ACL pravidlá |
| ir.model.fields | name | Char | — | Technický názov poľa |
| ir.model.fields | model_id | M2O | ir.model | Model |
| ir.model.fields | ttype | Selection | — | Typ poľa |
| ir.model.fields | relation | Char | — | Cieľový model (pre relational) |
| ir.model.fields | store | Boolean | — | Uložené v DB? |
| ir.model.fields | compute | Char | — | Compute metóda |

### ir.actions.server, base.automation a ir.cron

Viď hlavný SKILL.md a `references/architecture.md` pre detailné polia.

### ir.ui.view

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| name | Char | — | Názov view |
| model | Char | — | Cieľový model |
| type | Selection | — | form/list/kanban/search/graph/pivot/calendar/gantt |
| arch | Text | — | XML architektúra (JSONB v DB) |
| inherit_id | M2O | ir.ui.view | Parent view (inheritance) |
| priority | Integer | — | Priorita (lower = primary) |
| groups_id | M2M | res.groups | Viditeľnosť |

### ir.sequence

| Pole | Typ | Cieľ | Popis |
|---|---|---|---|
| code | Char | — | Kód sekvencie |
| prefix | Char | — | Prefix (napr. "SO") |
| padding | Integer | — | Zero-padding |
| number_next | Integer | — | Ďalšie číslo |
| company_id | M2O | res.company | Spoločnosť |

---

## Produkty

### product.template a product.product

```
product.template (šablóna — zdieľané vlastnosti)
  │
  ├─ name, list_price, type, categ_id, ...
  │
  └─ product_variant_ids → product.product[] (varianty)
        │
        └─ product_tmpl_id → product.template (reverse)
            default_code, barcode, ...
```

| Model | Pole | Typ | Cieľ | Popis |
|---|---|---|---|---|
| product.template | name | Char | — | Názov produktu |
| product.template | type | Selection | — | consu/service/product (v18: consu/service; v19: goods/service/combo) |
| product.template | categ_id | M2O | product.category | Kategória |
| product.template | list_price | Float | — | Predajná cena |
| product.template | standard_price | Float | — | Nákupná cena |
| product.template | uom_id | M2O | uom.uom | Merná jednotka |
| product.template | tracking | Selection | — | none/lot/serial |
| product.template | route_ids | M2M | stock.route | Procurement routes |
| product.product | product_tmpl_id | M2O | product.template | Šablóna |
| product.product | default_code | Char | — | Interná referencia |
| product.product | barcode | Char | — | Čiarový kód |

**Dôležité**: Väčšina FK v systéme ukazuje na `product.product` (variant), nie na `product.template`.
