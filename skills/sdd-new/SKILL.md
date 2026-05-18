---
model: sonnet
description: Start a new SDD change — runs explore + propose in sequence. Use as /sdd-new <change-name>.
---

# /sdd-new — New SDD Change

This is a **meta-command** that runs `/sdd-explore` then `/sdd-propose` in sequence.

## Step 0: Modo Aprendizaje (OBLIGATORIO — ejecutar ANTES de todo)

Preguntar UNA SOLA VEZ antes de continuar:

> "¿Desea aprender de lo que se va a construir? `sí` / `no`"

**DETENER y esperar respuesta del usuario antes de continuar.**

| Respuesta | Comportamiento |
|-----------|---------------|
| `sí` — módulo/código existente | Activar 6 capas desde UI de Odoo: Identificación → Estructura → Relaciones → Comportamiento → Seguridad → Flujo. Checkpoint entre capas — usuario implementa → Claude critica. |
| `sí` — concepto nuevo | Guiar al Técnico → ruta relevante para que el usuario lo descubra primero. |
| `no` o sin respuesta | Continuar con el flujo normal sin fricción. |

---

## Step 1: Verify SDD Initialization

 has been initialized:
Check that SDD- **engram**: `mem_search("sdd-init/{project}")` — if no result, run `/sdd-init` first
- **openspec**: Check if `openspec/config.yaml` exists — if not, run `/sdd-init` first
- **none**: Proceed with inline mode

## Step 2: Run Exploration

Execute the `/sdd-explore` workflow with the change topic/description.
Follow ALL its steps: load context, investigate codebase, analyze options, return structured analysis.

Save the exploration with the change name for traceability.

## Step 3: Present Exploration Results

Show the exploration results to the user and ask:
- Does the recommended approach look correct?
- Any adjustments needed before creating the proposal?

**STOP and wait for user confirmation before proceeding to proposal.**

## Step 4: Run Proposal

Once user approves, execute the `/sdd-propose` workflow.
Follow ALL its steps: create change directory, read existing specs, write proposal, persist.

## Step 5: Return Combined Summary

```markdown
## New Change Started

**Change**: {change-name}

### Exploration Summary
- **Recommendation**: {approach}
- **Affected Areas**: {count} files
- **Risk Level**: {Low/Medium/High}

### Proposal Summary
- **Intent**: {one-line}
- **Scope**: {N in, M deferred}
- **Approach**: {one-line}

### Next Steps
Ready for `/sdd-spec` and/or `/sdd-design`, or use `/sdd-ff {change-name}` to fast-forward all planning.
```

## Rules

- ALWAYS explore BEFORE proposing — never skip exploration
- ALWAYS stop and WAIT for user confirmation between explore and propose
- Change names should be kebab-case (e.g., `add-dark-mode`, `fix-login-bug`)
- The change name becomes the slug used in all subsequent artifacts
