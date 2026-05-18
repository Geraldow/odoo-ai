---
model: sonnet
description: Fast-forward through all SDD planning phases (propose → spec → design → tasks). Use as /sdd-ff [change-name].
---

# /sdd-ff — Fast-Forward SDD Planning

This is a **meta-command** that runs all planning phases in sequence WITHOUT stopping:
`propose → spec → design → tasks`

Use when you already know what you want to build and don't need to review each phase individually.

## Step 0: Modo Aprendizaje (OBLIGATORIO — ejecutar ANTES de todo)

Esta es una tarea de implementación mediana o grande. Antes de continuar, preguntar UNA SOLA VEZ:

> "¿Desea aprender de lo que se va a construir? `sí` / `no`"

**DETENER y esperar respuesta del usuario antes de continuar.**

| Respuesta | Comportamiento |
|-----------|---------------|
| `sí` — módulo/código existente | Activar 6 capas desde UI de Odoo: Identificación → Estructura → Relaciones → Comportamiento → Seguridad → Flujo. Checkpoint entre capas — usuario implementa → Claude critica. |
| `sí` — concepto nuevo | Guiar al Técnico → ruta relevante para que el usuario lo descubra primero. |
| `no` o sin respuesta | Continuar con el flujo normal sin fricción. |

Si `sdd-verify` se activa al cerrar → hacer 2-3 preguntas de comprensión al usuario antes de archivar.

---

## Step 1: Verify SDD Initialization

Check that SDD has been initialized:
- **engram**: `mem_search("sdd-init/{project}")` — if missing, run `/sdd-init` first
- **openspec**: Check `openspec/config.yaml` — if missing, run `/sdd-init` first

## Step 2: Run Proposal Phase

Follow ALL steps from `/sdd-propose`:
1. Create change directory (openspec) or prepare engram artifact
2. Read existing specs for context
3. Write proposal: intent, scope, approach, risks, rollback, success criteria
4. Persist artifact

## Step 3: Run Spec Phase

Follow ALL steps from `/sdd-spec`:
1. Identify affected domains from proposal
2. Read existing main specs (if any)
3. Write delta specs (or full specs for new domains)
4. Use Given/When/Then + RFC 2119 keywords
5. Persist artifact

## Step 4: Run Design Phase

Follow ALL steps from `/sdd-design`:
1. Read actual codebase before designing
2. Write design: technical approach, architecture decisions (with rationale), data flow, file changes, interfaces, testing strategy
3. Persist artifact

## Step 5: Run Tasks Phase

Follow ALL steps from `/sdd-tasks`:
1. Analyze design for file changes and dependency order
2. Organize tasks by phase (Foundation → Core → Integration → Testing → Cleanup)
3. Each task: specific, actionable, verifiable, small
4. Hierarchical numbering: 1.1, 1.2, 2.1, etc.
5. Persist artifact

## Step 6: Update State

Update DAG state with all completed phases:
- **engram**: `mem_save(title: "sdd/{change-name}/state", topic_key: "sdd/{change-name}/state", ...)`
- **openspec**: Update `state.yaml`

## Step 7: Return Combined Summary

```markdown
## Fast-Forward Complete

**Change**: {change-name}

### Proposal
- **Intent**: {one-line}
- **Scope**: {N in, M deferred}
- **Risk Level**: {Low/Medium/High}

### Specs
| Domain   | Type      | Requirements | Scenarios |
| -------- | --------- | ------------ | --------- |
| {domain} | Delta/New | {counts}     | {count}   |

### Design
- **Approach**: {one-line}
- **Key Decisions**: {N}
- **Files Affected**: {N new, M modified, K deleted}

### Tasks
| Phase   | Tasks | Focus  |
| ------- | ----- | ------ |
| Phase 1 | {N}   | {name} |
| Phase 2 | {N}   | {name} |
| Total   | {N}   |        |

### Next Step
Ready for `/sdd-apply {change-name}`.
```

## Rules

- Do NOT stop between phases — this is a fast-forward
- ALL four phases must complete for success
- If any phase encounters a BLOCKING issue, STOP and report
- Each phase MUST follow its full documented workflow steps
