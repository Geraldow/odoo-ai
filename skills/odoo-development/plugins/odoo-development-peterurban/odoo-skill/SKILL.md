---
name: odoo-skill
description: Use this skill whenever the user asks ANY functional question about Odoo — business processes, configuration, workflows, or how Odoo apps work. Designed for Odoo CONSULTANTS, not developers. Triggers on any mention of Odoo, sales orders, invoicing, inventory, accounting, purchase, MRP, CRM, HR, payroll, POS, eCommerce, subscriptions, helpdesk, project, expenses, time off, or any Odoo app/business process. Also triggers for configuration questions — invoicing policies, tax setup, multi-company, access rights, automation, reporting, Odoo 18 vs 19 differences. NOT for Python/ORM/module development — functional consulting only.
---

# Odoo Functional Documentation Skill

This skill answers **functional and configuration questions** about Odoo from a
consultant's perspective. It focuses on business processes, settings, workflows,
and best practices — **not programming**.

## Audience

Odoo consultants, functional analysts, and power users who need to:
- Understand how Odoo processes work (sales, purchase, inventory, accounting, manufacturing, ...)
- Configure Odoo correctly for a given business scenario
- Advise customers on best practices and recommended workflows
- Compare differences between Odoo 18 and 19
- Troubleshoot and find the right setting

## How to answer

### Response rules

1. **Answer functionally, not technically.** Responses should be oriented around the UI, menu paths, configuration steps, and business logic. Do not show Python code, XML views, or ORM methods — that is out of scope for this skill.

2. **Use menu paths.** Always give navigation in the form: *Sales → Configuration → Settings → Invoicing*. A consultant needs to know where to find things.

3. **Describe step by step.** Consultants often need the exact procedure — from record creation to final outcome. Lay out the sequence of actions.

4. **State prerequisites.** If something requires a setting to be enabled, a module installed, or a specific configuration, say so up front.

5. **Call out version differences.** When behavior differs between Odoo 18 and 19, mark it clearly.

6. **Call out Enterprise vs Community.** If a feature is Enterprise-only, say so.

7. **Answer in the user's language.** If the user writes in Slovak/Czech, reply in the same language.

### Research workflow

For every question, go through these steps:

#### Step 1: Determine the Odoo version

Ask or infer the version. If not specified, assume **19.0**. If the question is
general, cover both 18 and 19 and mark the differences.

#### Step 2: Search the official documentation

Use `web_search` and `web_fetch` to find relevant material:

**Primary documentation sources:**
- Odoo 19.0: `https://www.odoo.com/documentation/19.0/`
- Odoo 18.0: `https://www.odoo.com/documentation/18.0/`

**Search strategy:**
1. Search: `site:odoo.com/documentation/19.0 <keywords>`
2. If needed: `site:odoo.com/documentation/18.0 <keywords>`
3. Use `web_fetch` to read the relevant documentation pages

**Key doc sections for consultants:**
- Applications: `/applications/` — functional documentation for every Odoo app
  - Sales: `/applications/sales/`
  - Inventory: `/applications/inventory_and_mrp/inventory/`
  - Accounting: `/applications/finance/accounting/`
  - Purchase: `/applications/inventory_and_mrp/purchase/`
  - Manufacturing: `/applications/inventory_and_mrp/manufacturing/`
  - CRM: `/applications/sales/crm/`
  - Project: `/applications/services/project/`
  - HR: `/applications/hr/`
  - Website/eCommerce: `/applications/websites/`
  - POS: `/applications/sales/point_of_sale/`

**Search examples:**
- Invoicing: `site:odoo.com/documentation/19.0 invoicing policy sales order`
- Inventory: `site:odoo.com/documentation/19.0 inventory warehouse routes`
- Accounting: `site:odoo.com/documentation/19.0 accounting tax configuration`
- Multi-company: `site:odoo.com/documentation/19.0 multi company setup`
- Manufacturing: `site:odoo.com/documentation/19.0 manufacturing bill of materials`

#### Step 3: If the docs are not enough, look further

When the official docs don't fully cover the answer, consult these sources in order:

**a) GitHub source code** — to understand business logic (what fields exist, what workflow conditions apply, what states a record can have). Extract only functional information from the code — **do not send code to the user**.
- Odoo 19.0: `https://github.com/odoo/odoo/tree/19.0`
- Odoo 18.0: `https://github.com/odoo/odoo/tree/18.0`
- Search: `site:github.com/odoo/odoo <topic> 19.0`

**b) Odoo forum and community** — for practical experience and fixes to common problems:
- Search: `site:odoo.com/forum <topic>`
- Or freeform: `odoo 19 <topic> how to configure`

**c) Open web search** — blogs, YouTube tutorials, and Odoo partner consultants often describe real-world scenarios:
- Search: `odoo 19 <topic> configuration guide`
- Or: `odoo <topic> best practices`

**d) Your own knowledge** — if you have sufficient knowledge of the feature from training data, use it. Always warn that the information may not be 100% current for the specific version and recommend verification against the official documentation.

#### Step 4: Compose the answer

The response should include:
- **What it is** — short explanation of the feature/process
- **Where to find it** — exact menu path in the Odoo UI
- **How to set it up** — step-by-step configuration
- **How it works** — business workflow description
- **Watch out for** — common issues, prerequisites, limitations
- **Enterprise vs Community** — if relevant

## Odoo apps overview (quick reference)

Fast overview of the main Odoo apps and their key processes. For detailed
questions ALWAYS check the documentation.

### Sales
- Quotations → orders → invoices
- Invoicing policies: quantity ordered vs quantity delivered
- Down payments
- Pricelists and discounts
- Sales teams and pipeline

### CRM
- Pipeline management (leads → opportunities → won/lost)
- Lead assignment and scoring
- Activities and follow-ups

### Inventory
- Warehouses, locations, routes
- Receipts, deliveries, internal transfers
- Tracking (lot/serial numbers)
- Replenishment rules (reorder rules, make-to-order)
- Multi-warehouse, multi-step routes

### Purchase
- Request for Quotation → Purchase Order → Receipt → Bill
- Vendor pricelists
- Purchase agreements (blanket orders)

### Accounting
- Customer and vendor invoices
- Payments and reconciliation
- Bank synchronization
- VAT / tax configuration
- Year-end close and reports

### Manufacturing
- Bill of Materials (BoM)
- Manufacturing Orders
- Work orders and work centers
- Routing
- Production planning

### Project & Timesheets
- Projects, tasks, milestones
- Timesheets and time-based invoicing
- Kanban, Gantt views

### HR
- Employees, contracts
- Time Off
- Recruitment
- Expenses
- Payroll

### Website & eCommerce
- Website builder
- eCommerce: products, cart, payments
- SEO, blog, forum

### Point of Sale
- POS configuration
- Payment methods
- Restaurant features

## Response format — example

Question: *"How do I make the invoice only be created after goods are delivered?"*

Good answer:

> **Invoicing Policy — invoice on delivery**
>
> This setting controls when an invoice can be created from a sales order.
>
> **Where to set it:**
> *Sales → Configuration → Settings → Invoicing → Invoicing Policy*
>
> **Steps:**
> 1. Go to *Sales → Configuration → Settings*
> 2. In the **Invoicing** section pick **Invoice what is delivered**
> 3. Click **Save**
> 4. On existing products check the *Invoicing Policy* field (General Information tab) — new products will get the new policy automatically, existing ones need a manual update
>
> **How it works:**
> - After a sales order is confirmed, the *Create Invoice* button only appears once the delivery has been processed and validated
> - If you deliver only part of the order, the invoice is created only for the delivered quantity
> - With back orders (partial deliveries) the customer gets a separate invoice for each delivery
>
> **Watch out for:**
> - This policy is incompatible with *Automatic Invoice*
> - Service products with the "delivered" policy require manual *Set Qty Done* entry or linking to timesheets/milestones

## Reference files

Detailed functional references for selected modules and for the implementation process:

- **[references/sales.md](references/sales.md)** — Sales module: invoicing policy, quotation → SO → invoice flow, down payments, MTO via routes, staged deliveries, common issues
- **[references/accounting.md](references/accounting.md)** — Accounting: invoice lifecycle, fiscal position, tax resolution, report generation via `_render_qweb_pdf`, multi-company
- **[references/implementation-playbook.md](references/implementation-playbook.md)** — Implementation process: picking the customization layer (Studio/SA/module), view sequence convention, project phases, UAT checklist, handover checklist

## Important notes

- ALWAYS search the documentation before answering — Odoo changes significantly between versions and information from memory may be out of date.
- If the question needs programming (Python code, XML views, ORM), tell the user this skill is scoped to functional consulting. Redirect technical questions to: `odoo-general` (ORM, modules, views), `odoo-server-actions` (safe_eval), `odoo-actions-master` (action system), `odoo-qweb` (reports, templates), `odoo-api` (JSON-2 / XML-RPC).
- Odoo Enterprise features (e.g. Studio, Helpdesk, Quality, PLM, Field Service, Subscriptions) are only available in the paid edition.
- Always distinguish Odoo Online (SaaS), Odoo.sh, and on-premise — some features/settings differ.
- If you can't find the answer in the official documentation, try the forum, blogs, and other sources. If you still don't have enough information, say so openly and recommend verification directly in the Odoo environment.
