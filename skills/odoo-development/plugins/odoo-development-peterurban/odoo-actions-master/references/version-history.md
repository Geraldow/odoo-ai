# Odoo Action System — Version History (v8 → v19)

## Table of Contents

1. [Version Overview](#version-overview)
2. [Detailed Changelog](#detailed-changelog)
3. [Breaking Changes](#breaking-changes)
4. [Migration Notes](#migration-notes)

---

## Version Overview

| Version | Key changes in the action system |
|---|---|
| **v8** | Foundation — basic server actions, multi, object_create/write |
| **v9** | Stabilization, better safe_eval |
| **v10** | base_automation module stabilized |
| **v11** | on_time trigger, trigger_field_ids |
| **v12** | Better UI, extended action types |
| **v13** | Email/SMS/followers action types, improved condition evaluation |
| **v14** | Major UI overhaul, Studio integration, filter_pre_domain |
| **v15** | Multi-field triggers, time-based improvements |
| **v16** | Webhook, email variants (Message/Note), SMS variants |
| **v17** | on_change → "On UI Change", webhook trigger, terminology update |
| **v18** | numbercall/doall removed from ir.cron, security hardening |
| **v19** | AI integration, Command helper, improved error handling |

---

## Detailed Changelog

### v8 (2014) — Foundation

**Server Actions:**
- `ir.actions.server` with basic states: `code`, `object_create`, `object_write`, `multi`
- `condition` field for pre-execution check
- `fields_lines` for create/write operations
- Manual trigger via "More" menu

**Automated Actions:**
- `base_automation` module as an addon
- Basic triggers: on_create, on_write, on_unlink
- Simple domain filter
- No filter_pre_domain yet

**Safe_eval:**
- Basic sandbox with limited builtins
- datetime, time modules available
- Fewer restrictions than in newer versions

### v9-v10 (2015-2016) — Stabilization

**Changes:**
- base_automation becomes a more stable module
- Better documentation of the safe_eval context
- Improved error handling during execution
- `record`/`records` variables stabilized

**v10 specifics:**
- `<tree>` tag for list views (still before the transition to `<list>`)
- Automation rules UI simplified

### v11 (2017) — Time Triggers

**New:**
- `on_time` / `based_on_time_condition` trigger type
- `trg_date_id`, `trg_date_range`, `trg_date_range_type` fields
- `trigger_field_ids` for on_write — allows specifying WHICH fields
- Scheduler for time-based triggers (default 4h interval)
- Negative `trg_date_range` = before the date

**Impact:**
- Finally possible to build time-based automations without custom cron code
- Trigger field selection dramatically improves performance

### v12-v13 (2018-2019) — Extended Actions

**v12:**
- Improved UI for automation rules
- Better error reporting on execution failures
- Extended domain filter options

**v13:**
- **New action types**: `email`, `sms`, `followers`
- Email templates integration with automated actions
- SMS sending via automation rules
- Activity creation via automation
- Better condition evaluation with Python expressions

### v14 (2020) — Studio Integration Revolution

**Major changes:**
- **filter_pre_domain** (Before Update Domain) — NEW
  - Allows capturing state transitions (before + after)
  - This is a game-changer for workflow automations
- **Studio UI overhaul** — visual condition builder
- More descriptive action type names in the UI
- Improved automated actions documentation
- Studio Automated Actions tab

**Impact:**
- filter_pre_domain + filter_domain = elegant state machine patterns
- Studio users can create automation without the Technical Menu

### v15 (2021) — Multi-Field & Time

**Changes:**
- Better multi-field trigger handling
- Improved time-based trigger configuration
- XML-based automation rule creation documented
- Better Studio report designer
- Approval workflows beginning (early)

### v16 (2022) — Webhooks & Communication

**New:**
- **Webhook action type** — sends a POST request to an external URL
  - JSON payload with selected fields
  - Sample payload preview in configuration
- **Email variants**:
  - Email (SMTP)
  - Message (Discuss — followers see it)
  - Note (internal — internal users only)
- **SMS variants**:
  - SMS (no note)
  - SMS (with note)
  - Note only
- `on_change` / `on_form_change` trigger documented

**Impact:**
- Webhook = the first native way to integrate with an external system via automation
- Communication variants simplify notification workflows

### v17 (2023) — Terminology & Webhooks

**Changes:**
- **Rename**: "Based on Form Modification" → "On UI Change"
- **Webhook TRIGGER** — an external system can trigger an automated action
  - Odoo generates a unique webhook URL
  - External POST → runs the action
- Extended webhook capabilities (inbound + outbound)
- Standardized action type documentation
- Dark mode support in Studio
- `Command` helper for x2m operations available in the eval context
- Improved condition builder in Studio

**Impact:**
- Webhook trigger = Odoo as an event-driven system
- Command helper simplifies x2m writes:
  ```python
  record.write({'line_ids': [Command.create({'name': 'New line'})]})
  ```

### v18 (2024) — Simplification & Security

**Changes:**
- **REMOVED from ir.cron**: `numbercall` and `doall` fields
  - Interval-only scheduling
  - Run-once logic must live in the method code
- Improved safe_eval security
  - Stricter dunder restrictions
  - Better error messages on forbidden operations
- Improved error handling in automation rules
- Better integration with the Discuss module
- `type()` builtin REMOVED on SaaS

**Breaking changes:**
- Cron jobs that used numbercall (run X times and stop) must be rewritten
- doall (execute missed runs) also removed — scheduler is simplified

### v19 (2025) — AI & Polish

**Changes:**
- AI-powered suggestions for automation rules
- Better error handling and logging
- Improved webhook capabilities
- More granular execution control
- Performance improvements for large-scale automations
- Wizard defaults: `default_res_ids` (list) preferred over `default_res_id`

**Safe_eval (SaaS):**
- `type()` definitively DOES NOT WORK (NameError)
- `hasattr()`, `getattr()` — "forbidden opcode"
- String literals with dunder (e.g. `'__test__'`) — FORBIDDEN on save
- Stricter than on-premise

---

## Breaking Changes

### v14: filter_pre_domain added
- **Not breaking** — new field, default empty
- But automations without it may behave unexpectedly on upgrades if logic relied on an implicit pre-condition

### v17: on_change renamed
- `on_change` → "On UI Change" / `on_form_change`
- DB value remains `on_change` — only the UI label changed
- But new rules created via Studio may have a different internal value

### v18: numbercall/doall removed
- **BREAKING**: Cron jobs with `numbercall != -1` or `doall = True` lose this behavior
- **Migration**: Rewrite run-once logic into the method itself:
  ```python
  def _cron_one_time_job(self):
      if self.env['ir.config_parameter'].get_param('job_done'):
          return
      # do stuff
      self.env['ir.config_parameter'].set_param('job_done', 'True')
  ```

### v18-19: Safe_eval SaaS restrictions
- **BREAKING for SaaS**: `type()`, `hasattr()`, `getattr()` do not work
- Code that used them must be rewritten
- Dunder strings in code = server action cannot be saved

---

## Migration Notes

### Upgrading Automated Actions (v14 → v18/19)

1. **Check filter_pre_domain** — if missing, verify that the logic still works
2. **Check on_change triggers** — verify UI label vs DB value
3. **Check cron jobs** — remove reliance on numbercall/doall
4. **Test safe_eval code** — especially on SaaS, type()/hasattr()/getattr() do not work
5. **Check dunder strings** — `'__anything__'` in code = cannot be saved

### Upgrading Custom Modules (v16 → v18/19)

1. `<tree>` → `<list>` (since v17, tree deprecated)
2. Cron: remove `numbercall`/`doall` from XML data files
3. Wizard defaults: `default_res_ids` (list) instead of `default_res_id`
4. Command import: available in the safe_eval context since v17
5. Webhook: new capabilities for inbound triggers

### SaaS Migration Specifics

On SaaS you do not have access to:
- Custom modules (only Studio + automation rules)
- Server filesystem
- Shell/CLI
- Direct SQL (except env.cr in server actions)

Everything must work via:
- Studio UI
- Server actions (safe_eval)
- Automated actions
- Scheduled actions (via UI, not XML)
