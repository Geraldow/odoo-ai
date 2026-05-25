# Odoo Model Relationship Map — Cross-Module FK Diagram

## Table of Contents

1. [Cross-Module Flow Diagrams](#cross-module-flow-diagrams)
2. [Sales Flow](#sales-flow)
3. [Purchase Flow](#purchase-flow)
4. [Inventory/Warehouse](#inventorywarehouse)
5. [Accounting](#accounting)
6. [Manufacturing](#manufacturing)
7. [Project & Timesheets](#project--timesheets)
8. [CRM](#crm)
9. [HR](#hr)
10. [Core/Base](#corebase)
11. [Infrastructure/System](#infrastructuresystem)
12. [Product](#product)

---

## Cross-Module Flow Diagrams

### Sales → Delivery → Invoice (full flow)

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

### Manufacturing → Stock Consumption & Output

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

## Sales Flow

### sale.order

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | SO reference (SO0001) |
| partner_id | M2O | res.partner | Customer |
| partner_invoice_id | M2O | res.partner | Invoice address |
| partner_shipping_id | M2O | res.partner | Shipping address |
| order_line | O2M | sale.order.line | Order lines |
| picking_ids | O2M | stock.picking | Deliveries (reverse: sale_id) |
| invoice_ids | M2M | account.move | Invoices (via sale_order_invoice_rel) |
| user_id | M2O | res.users | Salesperson |
| team_id | M2O | crm.team | Sales team |
| company_id | M2O | res.company | Company |
| currency_id | M2O | res.currency | Currency |
| pricelist_id | M2O | product.pricelist | Pricelist |
| state | Selection | — | draft/sent/sale/done/cancel |
| date_order | Datetime | — | Order date |
| amount_untaxed | Monetary | — | Computed: untaxed amount |
| amount_tax | Monetary | — | Computed: tax amount |
| amount_total | Monetary | — | Computed: total amount |
| invoice_status | Selection | — | upselling/invoiced/to invoice/no |
| delivery_count | Integer | — | Computed: number of deliveries |

### sale.order.line

| Field | Type | Target | Description |
|---|---|---|---|
| order_id | M2O | sale.order | Parent order |
| product_id | M2O | product.product | Product |
| product_template_id | M2O | product.template | Product template |
| product_uom | M2O | uom.uom | Unit of measure |
| product_uom_qty | Float | — | Ordered quantity |
| qty_delivered | Float | — | Computed: delivered |
| qty_invoiced | Float | — | Computed: invoiced |
| qty_to_invoice | Float | — | Computed: to invoice |
| price_unit | Float | — | Unit price |
| discount | Float | — | Discount % |
| price_subtotal | Monetary | — | Computed: line amount |
| invoice_lines | M2M | account.move.line | Linked invoice lines |
| invoice_status | Selection | — | upselling/invoiced/to_invoice/no |

---

## Purchase Flow

### purchase.order

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | PO reference |
| partner_id | M2O | res.partner | Vendor |
| order_line | O2M | purchase.order.line | PO lines |
| picking_ids | O2M | stock.picking | Receipts (reverse: purchase_id) |
| invoice_ids | M2M | account.move | Vendor bills |
| state | Selection | — | draft/sent/to approve/purchase/done/cancel |
| date_order | Datetime | — | Order date |
| currency_id | M2O | res.currency | Currency |
| company_id | M2O | res.company | Company |

### purchase.order.line

| Field | Type | Target | Description |
|---|---|---|---|
| order_id | M2O | purchase.order | Parent PO |
| product_id | M2O | product.product | Product |
| product_qty | Float | — | Ordered quantity |
| qty_received | Float | — | Received quantity |
| qty_invoiced | Float | — | Invoiced quantity |
| price_unit | Float | — | Unit price |
| product_uom | M2O | uom.uom | Unit of measure |

---

## Inventory/Warehouse

### stock.warehouse

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Warehouse name |
| code | Char | — | Short code (WH, WH2) |
| lot_stock_id | M2O | stock.location | Main stock location |
| in_type_id | M2O | stock.picking.type | Receipt type |
| out_type_id | M2O | stock.picking.type | Delivery type |
| int_type_id | M2O | stock.picking.type | Internal transfer |
| company_id | M2O | res.company | Company |

### stock.location

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Location name |
| location_id | M2O | stock.location | Parent location (hierarchy) |
| warehouse_id | M2O | stock.warehouse | Owning warehouse |
| usage | Selection | — | internal/customer/vendor/inventory/view/production/transit |
| quant_ids | O2M | stock.quant | Stock at this location |
| company_id | M2O | res.company | Company |

### stock.picking

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Reference (WH/OUT/00001) |
| picking_type_id | M2O | stock.picking.type | Operation type |
| move_ids | O2M | stock.move | Moves in this transfer |
| sale_id | M2O | sale.order | Source SO |
| purchase_id | M2O | purchase.order | Source PO |
| origin | Char | — | Source document (text) |
| partner_id | M2O | res.partner | Partner |
| location_id | M2O | stock.location | Source location |
| location_dest_id | M2O | stock.location | Destination location |
| state | Selection | — | draft/waiting/confirmed/assigned/done/cancel |
| scheduled_date | Datetime | — | Scheduled date |
| date_done | Datetime | — | Completion date |

### stock.move

| Field | Type | Target | Description |
|---|---|---|---|
| picking_id | M2O | stock.picking | Parent transfer |
| product_id | M2O | product.product | Product |
| product_uom_qty | Float | — | Demand quantity |
| quantity | Float | — | Actual quantity (v19: quantity instead of quantity_done) |
| sale_line_id | M2O | sale.order.line | SO line (reverse trace) |
| purchase_line_id | M2O | purchase.order.line | PO line (reverse trace) |
| raw_material_production_id | M2O | mrp.production | Manufacturing order (consumption) |
| production_id | M2O | mrp.production | Manufacturing order (output) |
| location_id | M2O | stock.location | Source |
| location_dest_id | M2O | stock.location | Destination |
| move_dest_ids | M2M | stock.move | Downstream moves (chain) |
| state | Selection | — | draft/confirmed/assigned/done/cancel |

### stock.move.line (Detailed move — lot/serial level)

| Field | Type | Target | Description |
|---|---|---|---|
| move_id | M2O | stock.move | Parent move |
| product_id | M2O | product.product | Product |
| lot_id | M2O | stock.lot | Lot/serial number |
| location_id | M2O | stock.location | Source |
| location_dest_id | M2O | stock.location | Destination |
| qty_done | Float | — | Processed quantity |
| package_id | M2O | stock.quant.package | Package |
| owner_id | M2O | res.partner | Stock owner (consignment) |

### stock.quant (Current stock)

| Field | Type | Target | Description |
|---|---|---|---|
| product_id | M2O | product.product | Product |
| location_id | M2O | stock.location | Location |
| lot_id | M2O | stock.lot | Lot/serial |
| quantity | Float | — | On hand |
| reserved_quantity | Float | — | Reserved |
| owner_id | M2O | res.partner | Owner |
| package_id | M2O | stock.quant.package | Package |
| in_date | Datetime | — | Receipt date |

### stock.route & stock.rule

| Model | Field | Type | Target |
|---|---|---|---|
| stock.route | rule_ids | O2M | stock.rule |
| stock.route | warehouse_ids | M2M | stock.warehouse |
| stock.rule | route_id | M2O | stock.route |
| stock.rule | picking_type_id | M2O | stock.picking.type |
| stock.rule | location_src_id | M2O | stock.location |
| stock.rule | location_dest_id | M2O | stock.location |
| stock.rule | action | Selection | — (buy/manufacture/pull/push) |

---

## Accounting

### account.move (Journal Entry / Invoice)

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Document number |
| move_type | Selection | — | entry/out_invoice/in_invoice/out_refund/in_refund |
| partner_id | M2O | res.partner | Partner |
| journal_id | M2O | account.journal | Accounting journal |
| line_ids | O2M | account.move.line | Accounting lines |
| invoice_line_ids | O2M | account.move.line | Invoice lines (filter on line_ids) |
| state | Selection | — | draft/posted/cancel |
| date | Date | — | Accounting date |
| invoice_date | Date | — | Invoice issue date |
| invoice_date_due | Date | — | Due date |
| currency_id | M2O | res.currency | Currency |
| company_id | M2O | res.company | Company |
| origin | Char | — | Source document (SO name, PO name) |
| amount_total | Monetary | — | Total amount |
| amount_residual | Monetary | — | Unpaid residual |
| payment_state | Selection | — | not_paid/in_payment/paid/partial/reversed |

### account.move.line

| Field | Type | Target | Description |
|---|---|---|---|
| move_id | M2O | account.move | Parent document |
| account_id | M2O | account.account | Account |
| product_id | M2O | product.product | Product |
| partner_id | M2O | res.partner | Partner |
| debit | Monetary | — | Debit |
| credit | Monetary | — | Credit |
| balance | Monetary | — | Computed: debit - credit |
| price_unit | Float | — | Unit price |
| quantity | Float | — | Quantity |
| discount | Float | — | Discount % |
| tax_ids | M2M | account.tax | Taxes |
| sale_line_ids | M2M | sale.order.line | SO lines |
| purchase_line_id | M2O | purchase.order.line | PO line |

### account.payment

| Field | Type | Target | Description |
|---|---|---|---|
| partner_id | M2O | res.partner | Partner |
| partner_type | Selection | — | customer/supplier |
| journal_id | M2O | account.journal | Journal |
| amount | Monetary | — | Payment amount |
| payment_date | Date | — | Payment date |
| move_id | M2O | account.move | Generated journal entry |
| state | Selection | — | draft/posted/sent/reconciled/cancelled |
| currency_id | M2O | res.currency | Currency |

### account.journal

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Journal name |
| code | Char | — | Prefix (1-5 characters) |
| type | Selection | — | sale/purchase/general/cash/bank |
| company_id | M2O | res.company | Company |

### account.account

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Account name |
| code | Char | — | Account code |
| account_type | Selection | — | asset/liability/equity/income/expense/... |
| reconcile | Boolean | — | Allows reconciliation |
| company_id | M2O | res.company | Company |

### account.tax

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Tax name |
| type_tax_use | Selection | — | sale/purchase/none |
| amount | Float | — | Rate (e.g. 20.0) |
| amount_type | Selection | — | percent/fixed/group/division |

---

## Manufacturing

### mrp.production

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | MO reference |
| product_id | M2O | product.product | Produced product |
| product_qty | Float | — | Quantity to produce |
| bom_id | M2O | mrp.bom | Bill of Materials |
| picking_type_id | M2O | stock.picking.type | Operation type |
| move_raw_ids | O2M | stock.move | Component consumption |
| move_finished_ids | O2M | stock.move | Finished goods output |
| workorder_ids | O2M | mrp.workorder | Work orders |
| state | Selection | — | confirmed/progress/to_close/done/cancel |
| location_src_id | M2O | stock.location | Source location |
| location_dest_id | M2O | stock.location | Destination location |

### mrp.bom & mrp.bom.line

| Model | Field | Type | Target | Description |
|---|---|---|---|---|
| mrp.bom | product_tmpl_id | M2O | product.template | Product template |
| mrp.bom | product_id | M2O | product.product | Variant (optional) |
| mrp.bom | bom_line_ids | O2M | mrp.bom.line | Components |
| mrp.bom | type | Selection | — | normal/phantom (kit) |
| mrp.bom.line | bom_id | M2O | mrp.bom | Parent BOM |
| mrp.bom.line | product_id | M2O | product.product | Component |
| mrp.bom.line | product_qty | Float | — | Component quantity |

### mrp.workorder & mrp.workcenter

| Model | Field | Type | Target |
|---|---|---|---|
| mrp.workorder | production_id | M2O | mrp.production |
| mrp.workorder | workcenter_id | M2O | mrp.workcenter |
| mrp.workorder | operation_id | M2O | mrp.routing.workcenter |
| mrp.workorder | state | Selection | — (pending/ready/progress/done/cancel) |
| mrp.workcenter | name | Char | — |
| mrp.workcenter | resource_id | M2O | resource.resource |

---

## Project & Timesheets

### project.project

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Project name |
| partner_id | M2O | res.partner | Customer |
| task_ids | O2M | project.task | Tasks |
| sale_order_id | M2O | sale.order | Source SO |
| user_id | M2O | res.users | Project manager |
| company_id | M2O | res.company | Company |

### project.task

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Task name |
| project_id | M2O | project.project | Project |
| sale_line_id | M2O | sale.order.line | **KEY: Service SO line** |
| sale_order_id | M2O | sale.order | Source SO |
| user_ids | M2M | res.users | Assigned users |
| partner_id | M2O | res.partner | Customer |
| stage_id | M2O | project.task.type | Status (kanban stage) |
| parent_id | M2O | project.task | Parent task (subtasks) |
| child_ids | O2M | project.task | Sub-tasks |
| timesheet_ids | O2M | account.analytic.line | Timesheet entries |

**SO → Task link:** `project.task.sale_line_id` is an M2O to `sale.order.line`. When an SO line has a service product with the "Create Task" policy, a task is automatically created with this FK.

---

## CRM

### crm.lead

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Opportunity name |
| partner_id | M2O | res.partner | Contact |
| user_id | M2O | res.users | Salesperson |
| team_id | M2O | crm.team | Sales team |
| stage_id | M2O | crm.stage | Pipeline stage |
| type | Selection | — | lead/opportunity |
| probability | Float | — | Win probability |
| expected_revenue | Monetary | — | Expected revenue |
| order_ids | O2M | sale.order | Created SOs |

### crm.team

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Team name |
| member_ids | M2M | res.users | Members |
| user_id | M2O | res.users | Team leader |

---

## HR

### hr.employee

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Employee name |
| user_id | M2O | res.users | System account (optional) |
| address_home_id | M2O | res.partner | Private address |
| department_id | M2O | hr.department | Department |
| job_id | M2O | hr.job | Job position |
| parent_id | M2O | hr.employee | Manager |
| contract_ids | O2M | hr.contract | Contracts |
| resource_id | M2O | resource.resource | Resource (working hours) |
| company_id | M2O | res.company | Company |

### hr.contract

| Field | Type | Target | Description |
|---|---|---|---|
| employee_id | M2O | hr.employee | Employee |
| job_id | M2O | hr.job | Job position |
| date_start | Date | — | Start |
| date_end | Date | — | End |
| wage | Monetary | — | Wage |
| state | Selection | — | draft/open/close/cancel |
| resource_calendar_id | M2O | resource.calendar | Working hours |

### hr.leave & hr.leave.type

| Model | Field | Type | Target |
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

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Name / company name |
| email | Char | — | Email |
| phone | Char | — | Phone |
| parent_id | M2O | res.partner | Parent company |
| child_ids | O2M | res.partner | Company contacts |
| is_company | Boolean | — | Is it a company? |
| country_id | M2O | res.country | Country |
| state_id | M2O | res.country.state | State/region |
| customer_rank | Integer | — | >0 = customer |
| supplier_rank | Integer | — | >0 = vendor |
| company_id | M2O | res.company | Company |
| vat | Char | — | VAT ID |

### res.users (inherits res.partner)

| Field | Type | Target | Description |
|---|---|---|---|
| partner_id | M2O | res.partner | **Delegation inheritance** |
| login | Char | — | Login name |
| groups_id | M2M | res.groups | Groups/roles |
| company_id | M2O | res.company | Primary company |
| company_ids | M2M | res.company | Accessible companies |

### res.company

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | Name |
| parent_id | M2O | res.company | Parent company |
| child_ids | O2M | res.company | Subsidiaries |
| currency_id | M2O | res.currency | Currency |
| partner_id | M2O | res.partner | Company's partner record |

---

## Infrastructure/System

### ir.model & ir.model.fields

| Model | Field | Type | Target | Description |
|---|---|---|---|---|
| ir.model | model | Char | — | Technical name (sale.order) |
| ir.model | field_id | O2M | ir.model.fields | Model fields |
| ir.model | access_ids | O2M | ir.model.access | ACL rules |
| ir.model.fields | name | Char | — | Technical field name |
| ir.model.fields | model_id | M2O | ir.model | Model |
| ir.model.fields | ttype | Selection | — | Field type |
| ir.model.fields | relation | Char | — | Target model (for relational) |
| ir.model.fields | store | Boolean | — | Stored in DB? |
| ir.model.fields | compute | Char | — | Compute method |

### ir.actions.server & base.automation & ir.cron

See the main SKILL.md and `references/architecture.md` for detailed fields.

### ir.ui.view

| Field | Type | Target | Description |
|---|---|---|---|
| name | Char | — | View name |
| model | Char | — | Target model |
| type | Selection | — | form/list/kanban/search/graph/pivot/calendar/gantt |
| arch | Text | — | XML architecture (JSONB in DB) |
| inherit_id | M2O | ir.ui.view | Parent view (inheritance) |
| priority | Integer | — | Priority (lower = primary) |
| groups_id | M2M | res.groups | Visibility |

### ir.sequence

| Field | Type | Target | Description |
|---|---|---|---|
| code | Char | — | Sequence code |
| prefix | Char | — | Prefix (e.g. "SO") |
| padding | Integer | — | Zero-padding |
| number_next | Integer | — | Next number |
| company_id | M2O | res.company | Company |

---

## Product

### product.template & product.product

```
product.template (template — shared properties)
  │
  ├─ name, list_price, type, categ_id, ...
  │
  └─ product_variant_ids → product.product[] (variants)
        │
        └─ product_tmpl_id → product.template (reverse)
            default_code, barcode, ...
```

| Model | Field | Type | Target | Description |
|---|---|---|---|---|
| product.template | name | Char | — | Product name |
| product.template | type | Selection | — | consu/service/product (v18: consu/service; v19: goods/service/combo) |
| product.template | categ_id | M2O | product.category | Category |
| product.template | list_price | Float | — | Sales price |
| product.template | standard_price | Float | — | Cost |
| product.template | uom_id | M2O | uom.uom | Unit of measure |
| product.template | tracking | Selection | — | none/lot/serial |
| product.template | route_ids | M2M | stock.route | Procurement routes |
| product.product | product_tmpl_id | M2O | product.template | Template |
| product.product | default_code | Char | — | Internal reference |
| product.product | barcode | Char | — | Barcode |

**Important**: Most FKs in the system point to `product.product` (variant), not `product.template`.
