# Odoo Claude Skills

A curated set of [Claude Code](https://claude.com/claude-code) skills for
working with **Odoo 18 and 19 (SaaS, Enterprise, On-premise)**. Each skill
encodes conventions, gotchas, and verified API patterns so Claude can answer
questions and write code that runs on the first try.

> **Language:** English canonical sources live at the repo root. Slovak clones
> of the same skills live under [`sk/`](sk/) (prose only — code examples are
> identical).

---

## Skills

| Skill | Focus | When to use |
|---|---|---|
| [`odoo-general`](odoo-general/SKILL.md) | Core dev playbook: ORM, modules, views, Docker workflow, record rules | Writing/debugging Python, `@api.*`, views, module manifests |
| [`odoo-server-actions`](odoo-server-actions/SKILL.md) | `safe_eval` sandbox rules, forbidden builtins, dunder restrictions, patterns | Writing code that runs in a Server Action / Automated Action body |
| [`odoo-actions-master`](odoo-actions-master/SKILL.md) | Action-system encyclopedia: `base.automation`, `ir.actions.server`, `ir.cron`, model/FK map | Designing automations, chaining actions, mapping cross-module data flow |
| [`odoo-qweb`](odoo-qweb/SKILL.md) | QWeb: PDF/HTML reports, `mail.template`, view inheritance, wkhtmltopdf | Writing or debugging templates, inheritances, report layouts |
| [`odoo-visual`](odoo-visual/SKILL.md) | Visual decision layer: paperformat, Document Layout wizard, company branding, view attributes (decoration/widget/invisible), kanban cards, email colors, website/portal theme, asset bundles | Styling backend views, customizing PDF report appearance, aligning email + portal branding |
| [`odoo-api`](odoo-api/SKILL.md) | External API: JSON-2 (bearer auth), XML-RPC, meta-model operations | Scripting against a remote Odoo instance |
| [`odoo-skill`](odoo-skill/SKILL.md) | Functional consulting: menu paths, configuration, business workflows | Answering "how do I set up X in Odoo" without touching code |

### How the skills complement each other

```
                        ┌────────────────────────────────┐
                        │         odoo-skill             │
                        │  (functional consulting)       │
                        └────────────────────────────────┘
                                     │ redirects technical Qs to ↓
 ┌──────────────────┐  ┌────────────────────┐  ┌──────────────────────┐
 │  odoo-general    │  │ odoo-actions-master│  │     odoo-api         │
 │  (ORM, modules,  │  │  (action system,   │  │ (external JSON-2 /   │
 │   views, debug)  │  │   automations,     │  │   XML-RPC)           │
 │                  │  │   cron, model-map) │  │                      │
 └─────┬────────────┘  └─────────┬──────────┘  └──────────────────────┘
       │ redirects                │ redirects
       │ QWeb → ↓                 │ safe_eval → ↓
 ┌──────────────────┐      ┌──────────────────────┐
 │    odoo-qweb     │──┐   │ odoo-server-actions  │
 │ (reports,        │  │   │ (safe_eval sandbox   │
 │  templates,      │  │   │  rules, patterns)    │
 │  mail.template)  │  │   │                      │
 └──────────────────┘  │   └──────────────────────┘
                       │ QWeb mechanics deferred to by ↓
                 ┌──────────────────────────────┐
                 │       odoo-visual            │
                 │ (visual decision layer:      │
                 │  paperformat, Doc Layout,    │
                 │  branding, view attributes,  │
                 │  email/portal/website)       │
                 └──────────────────────────────┘
```

---

## Installing as Claude Code skills

### Option A — one skill at a time (selective)

Symlink or copy individual skill directories into your user-level skills folder:

```bash
# macOS / Linux
ln -s "$PWD/odoo-general" ~/.claude/skills/odoo-general
ln -s "$PWD/odoo-actions-master" ~/.claude/skills/odoo-actions-master
# ... etc.
```

```powershell
# Windows (PowerShell, admin)
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills\odoo-general" -Target "$PWD\odoo-general"
```

### Option B — plugin bundle

Wrap all six skills in a plugin (see
[Claude Code plugin docs](https://docs.claude.com/en/docs/claude-code/plugins))
and add a plugin `manifest.json` at the repo root. This repo does not currently
ship as a plugin — PRs welcome.

---

## Verification

All skills were last verified against these Odoo versions:

| Skill | Last verified | Odoo target |
|---|---|---|
| `odoo-general` | 2026-04 | 18, 19 |
| `odoo-server-actions` | 2026-02 | 19.0 SaaS |
| `odoo-actions-master` | 2026-03 | 18, 19 |
| `odoo-qweb` | 2026-04 | 18, 19 (SaaS + on-prem) |
| `odoo-visual` | 2026-04 | 18, 19 (SaaS + on-prem) |
| `odoo-api` | 2026-03 | 19.0 SaaS Enterprise |
| `odoo-skill` | 2026-04 | 18, 19 |

Skill content is versioned — re-verify against your target Odoo release if you
are on an older or newer version.

---

## Contributing

- Keep English and Slovak variants in sync. Editing a skill at the repo root?
  Apply the equivalent change in `sk/<skill>/`.
- Code blocks stay in English (Python/XML identifiers, Odoo model/field names)
  regardless of the surrounding prose language.
- Verify any new code example on a real Odoo instance before committing.
  Don't trust LLM-generated API calls — the API surface is wide and easy to
  get subtly wrong.

---

## License

Unreleased. Intended for internal use. Contact the repo owner before external
distribution.
