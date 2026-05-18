# Odoo Claude Skills — slovenská verzia

Slovenské klony skillov z koreňa repa. Kód a technické identifikátory ostávajú
v angličtine (to je konvencia Odoo); preložené sú iba popisy, prose a nadpisy.

> Kanonická (anglická) verzia skillov žije v koreni repa. Keď editujete
> anglickú verziu, aplikujte rovnakú zmenu tu v `sk/`.

## Skills

| Skill | Zameranie |
|---|---|
| [`odoo-general`](odoo-general/SKILL.md) | Jadro vývoja: ORM, moduly, views, Docker workflow, record rules |
| [`odoo-server-actions`](odoo-server-actions/SKILL.md) | Pravidlá safe_eval sandboxu, zakázané builtiny, dunder obmedzenia |
| [`odoo-actions-master`](odoo-actions-master/SKILL.md) | Encyklopédia action systému: `base.automation`, `ir.actions.server`, `ir.cron`, model/FK mapa |
| [`odoo-qweb`](odoo-qweb/SKILL.md) | QWeb: PDF/HTML reporty, `mail.template`, view inheritance, wkhtmltopdf |
| `odoo-visual` *(iba EN zatiaľ, [v koreni repa](../odoo-visual/SKILL.md))* | Vizuálna úprava: paperformat, Document Layout wizard, company branding, view atribúty, kanban karty, email farby, website/portal theme, asset bundles |
| [`odoo-api`](odoo-api/SKILL.md) | Externé API: JSON-2 (bearer auth), XML-RPC, meta-model operácie |
| [`odoo-skill`](odoo-skill/SKILL.md) | Funkčné konzultácie: menu cesty, konfigurácia, business workflow |

## Inštalácia ako Claude Code skills

Symlinkuj alebo skopíruj jednotlivé priečinky skillov do svojho user-level
skills folderu:

```bash
# macOS / Linux
ln -s "$PWD/sk/odoo-general" ~/.claude/skills/odoo-general
# ... atď.
```

```powershell
# Windows (PowerShell, admin)
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills\odoo-general" -Target "$PWD\sk\odoo-general"
```

## Poznámka o prekladoch

Kód (Python, XML, bash) a technické identifikátory (`sale.order`, `partner_id`,
`ir.actions.server`) NIE SÚ preložené — to sú API mená ktoré musia zostať
doslovné. Anglické technické výrazy ako *invoicing policy*, *sales order*,
*server action* sú zachované ako loan-words, kde je to v slovenskom IT
kontexte prirodzené.
