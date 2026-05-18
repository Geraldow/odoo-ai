# sdd-report — Development Closure Report

## Purpose

Generate a complete, professional closure report after a development task is finished.
Called by `sdd-apply` at the end of implementation. Read-only skill — never modifies code.

## Trigger

`sdd-apply` calls this skill after all tasks are marked complete, before saying "done".

---

## Output Rules

- Output the report DIRECTLY as rendered markdown — NEVER wrap in a code block (```markdown)
- Tables, bold, headers must render — no escaping
- Language: match the project language (Spanish if Odoo/Peru project, English otherwise)
- Audience: the full report serves developers, architects, QA, and Product Owners
- Length: complete but no filler — every section must add information

---

## Report Structure

### 1. Header

Metadata table — one glance, full context:

| Field | Content |
|-------|---------|
| Módulo / Module | technical name |
| Versión / Version | e.g. Odoo 18 Community |
| Entorno / Environment | Docker / Odoo.sh / staging |
| Fecha / Date | YYYY-MM-DD |
| Origen / Origin | Jira ticket / story reference |
| Rama / Branch | current git branch |

---

### 2. Contexto de negocio / Business Context

1–3 paragraphs. Why did the problem exist? What operational or business impact did it have?
No technical content yet. Written so a Product Owner or client can understand it.

---

### 3. Lo que se construyó / What Was Built

One block per task. Each block contains:
- **Qué** — what was built (one sentence)
- **Por qué** — why it was needed (what was wrong before)
- **Para qué** — what it enables (the user benefit)

---

### 4. Archivos tocados / Files Changed

Table with columns:

| Archivo | Acción | Qué cambió |
|---------|--------|------------|

Actions: `C` = Created / `M` = Modified / `F` = Fixed (corrected existing bug)

Be specific in "Qué cambió" — not "modified logic" but "added SEQUENCE_MAP, override button_confirm".

---

### 5. Modelos y campos / Models & Fields

Table with columns:

| Modelo | Campo | Tipo | ¿Escribe en DB? | Notas |
|--------|-------|------|-----------------|-------|

For `store=False` fields: explicitly state they only exist in memory.
For `related` fields: state what they point to.
For new `_name` models: note they create a new DB table.
For `_inherit` only: note no new table is created.

---

### 6. Decisiones técnicas / Technical Decisions

Table with columns:

| Decisión | Alternativa descartada | Por qué se eligió |
|----------|----------------------|-------------------|

Only include non-obvious decisions — ones a future developer might question.
Skip decisions that are standard/obvious patterns.

---

### 7. Technical Flows

One numbered flow per main user action. Each step shows what happens internally:
UI interaction → Python method → ORM call → PostgreSQL result.

Format:
```
Flujo N: [Action name]

1. User does X in UI
   └─ What Odoo does internally
   └─ What method is called
   
2. Method Y executes
   └─ What it reads/writes
   └─ What it returns

3. DB result
   └─ Table: column = value
```

Cover every significant action — not just the happy path.
Include: field changes, button clicks, settings saves, computed field recalculations.

---

### 8. Frontend → Backend

Per field or button that has non-obvious behavior:

```
Field name (widget type in XML)
  └─ @api.depends / @api.onchange / direct persist
  └─ store=True/False → DB impact
  └─ What triggers recalculation
  └─ DB column and table (if stored)
```

Skip fields with obvious standard behavior (e.g., a plain Char field).

---

### 9. Fuera de alcance / Out of Scope

Bullet list. What was deliberately NOT done and why.
Include: deferred tasks, pending migrations, features marked "Por determinar".

---

### 10. Cómo verificarlo en UI / How to Verify

Table with columns:

| Qué verificar | Ruta exacta |
|---------------|-------------|

Be precise — full navigation path, not just "go to purchase".
Include every feature delivered in section 3.

---

### 11. Cómo revertir / How to Rollback

Numbered steps. Concrete, executable. Include:
- How to uninstall the module (if applicable)
- What data remains in DB after uninstall
- Any manual cleanup needed

---

## Audience Guide (include at bottom of every report)

```
Product Owner / QA  →  secciones 1, 2, 3, 10
Developer           →  secciones 4, 5, 6, 7, 8
Arquitecto          →  secciones 6, 7, 8, 9, 11
```

---

## Rules

- NEVER skip a section — if there's nothing to put, write "N/A — [reason]"
- NEVER use vague language: "modified logic", "updated field", "changed behavior" — be specific
- NEVER wrap output in ```markdown — output directly as rendered markdown
- Section 7 (Technical Flows) is MANDATORY — it is the highest-value section for future developers
- Section 6 (Technical Decisions) must only include decisions a future dev would question
- The report is the LAST thing output before the session ends — after all code is written and verified
