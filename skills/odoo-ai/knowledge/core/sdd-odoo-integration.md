# SDD <-> odoo-ai Integration Rules

This document defines how Spec-Driven Development phases must cooperate with
the `odoo-ai` skill when an Odoo project or Odoo technical topic is involved.

## sdd-explore

Trigger: `__manifest__.py` detected, an Odoo module name is mentioned, or the
task requires understanding existing Odoo behavior.

Required script/tool: Run `scripts/module-intelligence.ps1` before analysis.
Use `scripts/odoo-version-detect.ps1` first when the module path is known.

Engram save: Save the module intelligence report with topic key
`odoo/module/{module}/intelligence`.

Example invocation:

```powershell
pwsh ~/.claude/skills/odoo-ai/scripts/odoo-version-detect.ps1 -Path .\{module}
pwsh ~/.claude/skills/odoo-ai/scripts/module-intelligence.ps1 -Path .\{module}
```

## sdd-propose

Trigger: A new Odoo change needs scope, intent, and boundaries before design.

Required script/tool: No source scan is required unless the proposal depends on
an existing module behavior. If it does, reuse the `sdd-explore` intelligence
artifact instead of rereading the source.

Engram save: Save proposal decisions with topic key
`sdd/{change}/proposal`.

Example invocation:

```text
/sdd-propose {change-name}
```

## sdd-spec

Trigger: User-facing behavior, acceptance scenarios, or business rules need to
be formalized for an Odoo change.

Required script/tool: Use the latest explore artifact for module context. Do
not inspect Odoo source unless a scenario references an existing behavior that
has not been explored.

Engram save: Save specifications with topic key `sdd/{change}/spec`.

Example invocation:

```text
/sdd-spec {change-name}
```

## sdd-design

Trigger: Any Odoo API, model method, decorator, manifest key, XML view pattern,
security rule, QWeb template, OWL component, controller, or hook is referenced
in the technical approach.

Required script/tool: Dot-source `scripts/Get-OdooConfig.ps1`, then verify exact
signatures and examples in `$cfg.EnterprisePath` first. If Enterprise is not
available, use `$cfg.CommunityPath` and mark the result as Community.

Engram save: Save architecture decisions with topic key `sdd/{change}/design`.
Also save non-obvious Odoo discoveries with `odoo/discovery/{topic-kebab}`.

Example invocation:

```powershell
. ~/.claude/skills/odoo-ai/scripts/Get-OdooConfig.ps1
rg "api.model_create_multi|__manifest__|ir.rule" $cfg.EnterprisePath
```

## sdd-tasks

Trigger: Design is approved and needs an implementation checklist.

Required script/tool: Derive tasks from the spec and design artifacts. Include
explicit Odoo verification tasks for ACL, XML inheritance, migrations, and test
runner usage when applicable.

Engram save: Save task breakdown with topic key `sdd/{change}/tasks`.

Example invocation:

```text
/sdd-tasks {change-name}
```

## sdd-apply

Trigger: Any code, XML, security CSV, migration script, QWeb, OWL, or automation
is written for an Odoo module.

Required script/tool: Load `odoo-ai` and `RULES.md` before writing code. Apply
R1 version detection, R4 ACL checks, R5 pre-migrate rules for XML view changes,
and Enterprise First verification for APIs used during implementation.

Engram save: Save completed development with topic key
`odoo/dev/{module}/{feature-kebab}`. Save granular discoveries immediately with
`odoo/{category}/{topic-kebab}`.

Example invocation:

```powershell
pwsh ~/.claude/skills/odoo-ai/scripts/odoo-version-detect.ps1 -Path .\{module}
pwsh ~/.claude/skills/odoo-ai/scripts/acl-validator.ps1 -Path .\{module}
```

## sdd-verify

Trigger: Implementation is complete or ready for validation.

Required script/tool: Use `scripts/test-runner.ps1` for Odoo module tests. Use
`scripts/view-xpath-validator.ps1` when XML inheritance changed. Use PowerShell
AST checks for modified `.ps1` scripts.

Engram save: Save verification report with topic key
`sdd/{change}/verify-report`.

Example invocation:

```powershell
pwsh ~/.claude/skills/odoo-ai/scripts/test-runner.ps1 -Module {module} -Database {db}
pwsh ~/.claude/skills/odoo-ai/scripts/view-xpath-validator.ps1 -Path .\{module}
```
