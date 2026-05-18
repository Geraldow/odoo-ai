---
name: odoo-general
description: Core Odoo development playbook. Read whenever working with Odoo modules, models, fields, ORM, server-side code, views (form/list/kanban/search), manifests, module structure, deployment, Docker workflow, Studio, record rules, CRUD, or any Odoo admin/config task. Covers environment/Docker workflow, hot-reload rules, module manifest layout, common errors table, ORM patterns, CRUD gotchas, record rules, Studio view recovery, and deployment routine. Does NOT cover QWeb/templates/reports (use odoo-qweb), server action safe_eval (use odoo-server-actions), external JSON-RPC/JSON-2 API (use odoo-api), action system architecture and automated actions (use odoo-actions-master), or functional consulting (use odoo-skill).
---

Directives: Follow strictly. Do not assume standard Python/JS logic applies without Odoo context.

Google first for arch/fields/xpath patterns. SSH only for DB data. Deploy First: Upload->Update->Check Logs. Prefer NOT to use research scripts, arch dumps, or regex pre-checks, just let the user test instead.

**For QWeb work (PDF/HTML reports, mail.template body_html, view inheritance via xpath, t-* directives, wkhtmltopdf, ir.ui.view editing): STOP and read odoo-qweb skill first.** It owns: directives, t-field/t-out/t-esc, inheritance modes, XPath patterns, mail.template two-engine model, wkhtmltopdf gotchas, version migration matrix (14-19), financial reports, encoding (SK/CZ diacritics), template debug workflow. This skill (odoo-general) does NOT duplicate that content.

# 1. Environment, Docker & Workflow
- Restart: docker ps -> docker restart <n> -> docker logs <n> (catch registry load failures).
- Hot-Reload (our Docker setup): Python changes => restart container. XML/JS => -u module.
- Assets: JS/CSS changes -> -u module -> Clear Assets (Debug Mode) -> Clear Browser Cache.
- Load Order: ACLs -> Record Rules -> Data -> Views (fields must exist).
- Migrations/Prod: Keep one-off scripts in post_init / post_migration. Prefer ORM; use raw SQL only when necessary.

# 2. Models & ORM Patterns
- Naming: UI created = x_ prefix. Module code = no prefix.
- M2O Rules:
  - Required (required=True): use ondelete='restrict' or 'cascade'; avoid 'set null' (causes Registry Load Failure).
- XMLID Refs: Use env.ref('module.xml_id', raise_if_not_found=False) for optional references.
- Logic Tree:
  - Propagate M2O -> related (stored).
  - Aggregate O2M -> compute (store=True).
  - Dynamic UI -> @api.onchange (No business logic).
  - Validation -> @api.constrains (ORM) or _sql_constraints (DB).
  - Context Dep -> @api.depends_context('company', 'lang').
  - Existence check (bypass ACLs) -> any! / not any! operators.
- Automation Triggers (O2M): Parent *On Update* ignores O2M line changes. Trigger on Child model; write() aggregate/status to Parent.
- Create overrides: use @api.model_create_multi only; call super and return recordset.
- Timezones: Display: fields.Datetime.context_timestamp(self, dt). Never hardcode timezone offsets.
- Sequences: Use self.env['ir.sequence'].next_by_code('code'). Never MAX(id)+1.
- Cache: After raw SQL/external changes: call env.invalidate_all() or records.invalidate_recordset().
- Server Actions (safe_eval): import blocked; use preloaded globals. Prefer record.write(); use log()/message_post(); loop records. Wizard defaults (19+): default_res_ids list; default_res_id can raise ValueError. For "do logic + open wizard": write first, return ir.actions.act_window (Automated Actions can't return UI). When wrapping Window Action by ID, merge its context to preserve defaults.

# 3. Action Buttons & Studio
- Action buttons in views: `domain="..."` can be ignored (17+). Prefer Server Action returning ir.actions.act_window dict with explicit domain + target.
- Studio Field Suffix: Deleting/recreating Studio fields can produce x_field_1. Always verify Technical Name before domains/actions.
- Server Action Binding: If Studio drops the selected Server Action on a button, create/enable a context action; if needed bind by action ID.
- Operational vs Analytical Fields: Don't mix "operational flags" (must reset after action) with "analytical history" (should be immutable).
- API: Use API Key/Password. SSO fails with XML-RPC.
- Test Mode: Use for manual crons / technical actions on SaaS.

# 4. Frontend (OWL/JS)
- DOM Integrity: In OWL-managed DOM, don't use node.remove(); use t-if / t-foreach / classes.
- OWL: Don't use constructor(); init in setup().
- Reactivity:
  - No deep mutation. state.items = [...state.items, new].
  - Don't recast reactive arrays (Proxies) to plain JS (breaks Record/Reconciler). Use getters.
  - Templates: t-inherit: Verify scope (this vs component) and that t-set doesn't overwrite getters.
- Async: Sync overrides calling async? Use void this.asyncMethod() or await only if caller expects Promise.
- Services:
  - Registration: registry.category("services").add("name", { dependencies: [], start() {} }).
  - Notifications: notification.add returns cleanup. Overrides must return cleanup.
- Realtime: Backend env['bus.bus']._sendone -> Frontend bus_service subscribe.

# 5. Security & Multi-Company
- Layers: ACLs (Access) -> Rules (Filter).
- Rules Trap: [('id', 'in', [])] blocks ALL records.
- Admin: Only UID 1 ignores rules. Admin groups need explicit [(1,'=',1)].
- Sudo: Avoid. Bypasses all security layers.
- Multi-Company:
  - Default: default=lambda s: s.env.company.
  - Rule (Std): [('company_id', 'in', user.company_ids.ids)].
  - Rule (Shared): ['|', ('company_id', '=', False), ('company_id', 'in', user.company_ids.ids)].
- Domain Limits:
  - No field-to-field compare (e.g. ('date_done','<=','commitment_date')); denormalize into a stored helper field.
  - ('field','!=','x') excludes False; use ['|', ('field','=',False), ('field','!=','x')] or backfill.
  - Domains over O2M: Simple domains can't express ALL/ANY reliably; denormalize status to the parent.

# 6. Domain Specifics
- Mail (broader notes; mail.template rendering itself = odoo-qweb skill):
  - Recursion Guard: if self.env.context.get('__guard'): return.
  - Params: scheduled_date is kwarg, NOT context.
  - Mail Gateway: Avoid Automated Actions on mail.message (esp. *On Create*). Uncaught exceptions break catchall. Mandatory try/except Exception: pass.
- Translations: from odoo import _ (NEVER from self.env).
- CRM (SaaS):
  - crm.stage may not have team_id (Invalid field 'team_id' in leaf); don't domain-filter by it.
  - Avoid searching config by name (typos/diacritics). Prefer XML IDs; otherwise a verified stable DB ID.
- Documents:
  - Breadcrumb "Project / Task" != Folder. It denotes res_model link.
  - Hierarchy defined strictly by folder_id / parent_id.
- Inventory: Avoid writing to stock.quant. Use _update_available_quantity or stock.move.
- Picking Automations: In Automated Actions on stock.picking, guard by picking_type_id.code to avoid wrong flows.
- Accounting (Down Payment):
  - Detection: line.is_downpayment (bool). display_type is 'product', not False.
  - Trigger: "On Update" of invoice_line_ids (avoids duplicate runs).
- Cron (17+): No numbercall/doall. Use interval. Run-once logic in code.
- Removed (19+): stock.valuation.layer (use stock.move), hr.employee.base.
- Odoo Sign: Single-line autosizes; use Multiline for smaller font. Field type immutable (recreate = new Variable Name). Variable Name changes (e.g., ..._1) on recreate; restore or writes silently fail. PDF background immutable; edit externally. Word source: use "Wrap Text -> Behind Text" for transparency.

# 7. Critical Debugging (Create/Write Crashes)
When UI crashes on create/write (UncaughtPromiseError, 500), UI traceback is often misleading.
- **Network Tab is Authority**: DevTools > Network > last RPC request (/web/dataset/call_kw). Response payload contains real traceback (200 OK + error JSON, 500 crash, or 403 security). Server logs are secondary.
- **Zombie Configs** (most common after Studio changes):
  - ir.default: Hardcoded defaults for deleted/renamed fields. Search model defaults; delete only broken entries.
  - ir.actions.act_window context: {'default_x_studio_field': ...} for non-existent fields. Crashes on form open (onchange) or save.
  - Hidden Views: Active views from uninstalled modules injecting invalid fields. Archive them.
- **Computed Fields Triage**: Fields with compute=True + store=True crash on save. Isolate: set store=False temporarily (moves crash from save to read). NOT a fix - just diagnostic. Then neutralize: replace compute logic with dummy (for rec in self: rec['field'] = False) to preserve structure without toxic logic.
- **Transaction/Cache**: raise UserError in Server Action = ROLLBACK (changes lost). Use return display_notification instead. After ir.model.fields / ir.ui.view changes: Hard Refresh (Ctrl+F5) mandatory or UI sends stale schema.
- **DB Integrity**: If ORM diagnosis fails (e.g., "not-null violation" on optional field), use read-only SQL to check constraints/NULLs ORM doesn't know about. INSERT/UPDATE via SQL bypasses audit/automations - test DB only.

# 8. Error Reference (non-template)
QWeb / view / template errors: see odoo-qweb § 16.
| Error | Cause | Fix |
| --- | --- | --- |
| Invalid field 'X' in leaf | Domain refs missing field. | Fix domain or grant read access. |
| Registry Load Failure | Required M2O + ondelete='set null'. | Use restrict/cascade. |

# 9. Data Migration / ETL
- Headers/Encoding: CZ/SK exports often cp1250. Non-ASCII/mojibake: use df.iloc[:, idx]; dump df.columns + df.head().
- Verification: Inspect sample output rows + key IDs/codes. Never trust exit codes/row counts alone.
- Source-first Debug: If output wrong (e.g., price=0), SQL-check source row before debugging mapping.
- Schema Discovery: List tables/columns first (sys.tables, INFORMATION_SCHEMA.COLUMNS) before joins; never assume names exist.
- Schema parity: Don't assume related datasets share columns; verify FK columns before mapping.
- Dedup: Stage 1 drop clones; Stage 2 rename conflicts (preserve both).
- Large base64: chunk reads; keep imports <100MB.

# 10. Odoo 19 / Remote Dev
- Module Install: odoo-bin -i module --stop-after-init (or -u for updates). Hangs = uncommitted transactions/running instances/locks/longpolling, not CLI. Avoid shell button_immediate_install hacks.
- File Transfer: cat = unreliable for binary/UTF-8 (corruption/truncation). Scrambled output = stop using cat; use scp, rsync, or base64 -w0.

Odoo online / SaaS - safe_eval limits apply
what won't work:
imports
hasattr
getattr
global
...
