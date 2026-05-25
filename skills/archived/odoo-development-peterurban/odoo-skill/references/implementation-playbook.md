# Odoo Implementation Playbook

Process guidance for consultants scoping and executing an Odoo implementation.
Focused on project-level decisions, not code patterns (those live in
odoo-general, odoo-server-actions, and odoo-actions-master).

---

## Customization layers — pick the lowest that works

| Need | Tool | Why |
|---|---|---|
| Add a field / button / simple view change | **Studio** | No module, no code, survives SaaS |
| Conditional field update, send notification, domain-driven flow | **Automated Action** (base.automation) | Hooked in ORM events, Studio-compatible |
| Manual one-off logic on demand | **Server Action** with safe_eval | Fits on a form button |
| Complex business logic, new models, external integrations | **Custom module** (Odoo.sh / on-prem) | Required once you need imports, new classes, or heavy compute |

Rule of thumb: go up one level only when the current one blocks you. On Odoo
Online SaaS, custom modules are not an option — everything must fit in
Studio + Automated Actions + Server Actions.

---

## View sequence convention

| Source | Typical sequence |
|---|---|
| Core Odoo views | 0 – 99 |
| Addon-module inherited views | 100 – 159 |
| Studio-generated views | 160+ |
| Your inheritances that must win over Studio | 200+ |

Higher sequence applies later and wins the tug-of-war. If a Studio field
disappears after you inherit a view, bump your sequence to 200+.

---

## Typical implementation phases

1. **Discovery**
   - Workshop: map each business process to Odoo apps.
   - Identify gaps (custom fields, reports, workflows, integrations).
   - Document version (18 vs 19), edition (Community vs Enterprise), hosting (Online vs .sh vs on-prem) — these constrain every later choice.
2. **Design**
   - Data migration plan (sources, mappings, dedup strategy).
   - Customization inventory: Studio items, automated actions, custom modules.
   - Access model: companies, groups, record rules.
3. **Build**
   - Configure core apps end-to-end before adding customizations.
   - Customize last — easier to drop a Studio field than rebuild it.
4. **Data load**
   - Load reference data (products, partners, CoA) before transactional (SO, invoices, stock).
   - Validate row counts AND sampled rows (exit codes lie).
5. **UAT**
   - Test the golden path AND the edge cases customer cares about.
   - Record access-rights testing per role, not just "admin works".
6. **Go-live**
   - Freeze customizations 1 week before cutover.
   - Cut historical data at a clear boundary (e.g., open invoices only, paid ones stay in legacy).
   - Keep a rollback plan for the first 48 hours.

---

## Testing strategy

### Minimum checklist before go-live

- [ ] Create SO → confirm → deliver → invoice → register payment (end-to-end)
- [ ] Purchase: RFQ → PO → receive goods → bill → pay
- [ ] Financial: post manual journal entry → run Balance Sheet / P&L
- [ ] Access: log in as each role (sales user, warehouse user, accountant, manager) and verify visibility
- [ ] Custom fields render correctly on all affected views (form, list, kanban, search)
- [ ] Server actions execute without errors for at least one record
- [ ] Automated actions fire on the intended trigger and not on unrelated records
- [ ] Reports generate (PDF and screen) for a real record
- [ ] Emails send from the test environment (template + mail server)

### Data validation

Never trust row counts alone. Sample and eyeball:
- Any row with a unique natural key (order number, PO number, customer code).
- Any row with currency or quantity — verify arithmetic on import totals.
- Translations: if multi-language, open a few records in non-default language.

---

## Handover checklist

Document these; hand to the customer's internal admin or next consultant.

- **Custom fields** — model, technical name, type, where shown, purpose
- **Automated / server actions** — trigger, model, what it does, author, owner
- **Scheduled actions (ir.cron)** — interval, code owner, failure contact
- **Access model** — groups, which groups see/edit which records, where the rules live
- **Integrations** — external system, auth method, endpoints, credentials location, error channels
- **Data migration scripts** — how to re-run, where sources live, what to do on failure
- **Go-live runbook** — rollback procedure, contacts, known issues

If the customer is on SaaS, also document how to regenerate API keys,
who has admin access, and where the Odoo billing contact lives.
