---
name: odoo-ai-rules
description: Reglas maestras de desarrollo Odoo — template genérico para cualquier equipo. Se leen SIEMPRE antes que cualquier plugin.
license: LGPL-3
metadata:
  author: Geraldow
  version: "1.0.0"
  last-updated: "2026-05-20"
---

# RULES — Odoo Development
# Propietario: Geraldow
# ESTE ARCHIVO SE LEE SIEMPRE PRIMERO — antes de cualquier plugin

---

## REGLA 0 — Leer este archivo primero

Antes de cargar cualquier plugin, ejecutar cualquier script, o escribir cualquier código:
**Leer y aplicar todas las reglas de este archivo.**

Los plugins (fhidalgo, unclecatvn, ahmedlakos, etc.) son LIBRERÍAS DE REFERENCIA — snippets y patrones.
Las REGLAS que gobiernan el comportamiento viven aquí, no en los plugins.

---

## R1 — Detección de versión Odoo (OBLIGATORIO)

Antes de escribir cualquier código Odoo:
1. Leer `__manifest__.py` → extraer versión (ej. `18.0.1.2` → Odoo 18)
2. Extraer edition: `license: 'OEEL-1'` → Enterprise | `LGPL-3` / `AGPL-3` / `OPL-1` → Community
3. Si no hay `__manifest__.py` → preguntar al usuario antes de continuar

**Nunca asumir la versión. Nunca escribir código v17 para un proyecto v18.**

---

## R2 — Branch Safety (OBLIGATORIO antes de cualquier git)

```
st_<proyecto>    → ✅ Permitido
st_produccion    → ✅ Permitido
produccion       → 🔒 DETENERSE — pedir autorización explícita
db_<proyecto>    → 🔒 DETENERSE — pedir autorización explícita
```

Operaciones BLOQUEADAS permanentemente (sin excepción):
- `git push --force` o `git push -f`
- `git push origin --delete <branch>`
- `git rebase` (cualquier variante)
- `git reset --soft/--mixed/--hard`

**Push SIEMPRE requiere pausa y "sí" explícito del usuario antes de ejecutar.**

---

## R3 — Verificación de identidad antes de commit/push

Antes de `git commit` o `git push` en cualquier proyecto Odoo:

```bash
git config user.name
git config user.email
```

Cruzar contra los contribuidores autorizados en la lista del equipo:
`[RUTA_A_TU_CONTRIBUTING.md]` (ej. `~/.claude/skills/odoo-ai/plugins/odoo-development-[tu-equipo]/CONTRIBUTING.md`)

Si NO coincide → **DETENERSE completamente y alertar al usuario.**

Proyectos en scope: `[PROYECTO_1]`, `[PROYECTO_2]`, `[PROYECTO_3]` (personalizar con la lista de proyectos de tu equipo)

---

## R4 — Seguridad obligatoria en nuevos modelos

Todo modelo nuevo (`models.Model`) DEBE tener:
- Entrada en `security/ir.model.access.csv`
- Al menos permisos `read` para `base.group_user`

Sin esto → el módulo falla en instalación o el usuario no puede ver los registros.

**Verificar antes de hacer commit:** ¿Hay modelos nuevos? ¿Tienen ACL?

---

## R5 — Pre-migrate obligatorio al cambiar vistas XML

**Trigger:** versión bumped en `__manifest__.py` + archivos `.xml` de vistas modificados en el mismo commit.

**Acción:** Crear `migrations/<version>/pre-migrate.py`:

```python
# -*- coding: utf-8 -*-
def migrate(cr, version):
    cr.execute("""
        DELETE FROM ir_ui_view
        WHERE name IN ('nombre.de.la.vista.modificada')
          AND model = 'el.modelo'
    """)
```

El `name` corresponde al `<field name="name">` del `<record model="ir.ui.view">` en el XML.

**Sin este script → Odoo.sh muestra `Test: Warning` al hacer `-u` (upgrade) sin desinstalar.**

---

## R6 — Buscar antes de construir (No reinventar la rueda)

Antes de desarrollar cualquier funcionalidad nueva:
1. Buscar en Enterprise source: `Grep $cfg.EnterprisePath --include="*.py" -r "{keyword}"` (Enterprise First)
2. Si no encontrado en Enterprise → buscar en Community: `$cfg.CommunityPath\{version}\`
3. Buscar en OCA: `https://github.com/OCA?q=<keyword>`
4. Solo desarrollar desde cero si no existe en ningún lado

**Enterprise First** → Grep acotado al módulo → Read archivo específico.
Si hay resultado en Enterprise, es el definitivo — no buscar en Community.

---

## R7 — Estándares de código

- **Python**: PEP8, SOLID, DRY. Usar `super()`. Sin decoradores obsoletos (`@api.multi`).
- **ORM v18**: `@api.model_create_multi` para `create()`. Nunca `@api.multi`.
- **Traducción**: `_("texto")` nunca `_(f"texto {var}")` — usar `_("%s texto") % var`.
- **Loops en compute**: siempre `for record in self:`, nunca `self.field` dentro del loop.
- **Multi-empresa**: siempre `self.env['ir.sequence'].with_company(company).next_by_code(...)`.
- **XML invisible v18**: `invisible="condición"` — nunca `attrs="{'invisible': [...]}"`.
- **XML IDs**: verificar que existen antes de heredar con `ref=`.

---

## R8 — Secuencias personalizadas en Odoo 18

Cuando un módulo define secuencias propias (`ir.sequence`):
- `create()` debe asignar la secuencia personalizada (no dejar la nativa)
- `write()` debe reasignar si cambia el tipo en draft
- `button_confirm()` debe verificar `order.name.startswith(seq.prefix)` antes de reasignar
- `sequence_preview` (vista draft): condicionar por `id` — sin `id` = no guardado = mostrar preview; con `id` = guardado = mostrar `name`

---

## R9 — Commits

- Formato convencional: `feat|fix|docs|style|chore|refactor|perf|test(scope): mensaje`
- NUNCA agregar `Co-Authored-By` ni atribución de IA
- NUNCA usar `--no-verify`
- NUNCA hacer build después de los cambios (Odoo.sh lo hace automático)

---

## R10 — Consulta Enterprise source (sdd-design / sdd-apply)

Para cada API de Odoo usada en diseño o implementación (hook signature, decorador, campo, XML key):
- `Grep $cfg.EnterprisePath --include="*.py" -r "{api_name}"` (Enterprise First)
- Si no encontrado → `Grep $cfg.CommunityPath\{version}\ --include="*.py" -r "{api_name}"`
- Source Enterprise local: `$cfg.EnterprisePath` (fuente primaria — todas las versiones)
- **Nunca asumir el formato — siempre verificar contra source real**

---

## R11 — Clasificación de tareas (SDD enforcement)

| Tamaño | Criterio | Flujo |
|--------|----------|-------|
| Consulta | pregunta, lookup, explicación, error | Responder directo |
| Sencillo | 1 archivo, 1-2 cambios, bug fix puntual | Implementar directo + engram save |
| Moderado | 2+ archivos, lógica nueva, modelo nuevo con vistas | `/sdd-ff` primero |
| Complejo | módulo nuevo, multi-archivo, cross-module | `/sdd-ff` primero |

**Engram save obligatorio** si hay contexto Odoo: modelos, módulos, vistas, campos, ORM, XML, errores, discoveries.

---

## R12 — Contexto de tokens (eficiencia)

- **NO** leer source de Odoo completo — usar `Grep` acotado con ruta específica (Enterprise First)
- **NO** hacer SSH al servidor para explorar código → leer local
- **NO** usar `tail -200` en archivos grandes → leer con `limit` y `offset`
- **NO** cargar todos los archivos de `knowledge/` → cargar solo el archivo relevante
- **NO** leer `plugins/` durante triggers automáticos → usar `knowledge/` directo
- `knowledge/` es bajo demanda: cargar solo el archivo que corresponde al contexto actual

---

## R13 — Seguridad obligatoria en código Odoo

Estas reglas aplican a TODO código escrito — sin excepción.

**SQL — siempre parámetros, nunca concatenación:**
```python
# ❌ NUNCA
cr.execute("SELECT id FROM res_partner WHERE name = '%s'" % name)
# ✅ SIEMPRE
cr.execute("SELECT id FROM res_partner WHERE name = %s", (name,))
```

**sudo() — scope mínimo, siempre justificado:**
```python
# ❌ sudo() global sin verificación
record = self.env['sale.order'].sudo().browse(order_id)
# ✅ verificar propietario antes de operar
record = self.env['sale.order'].sudo().browse(order_id)
if record.partner_id != self.env.user.partner_id:
    raise AccessError(_("Access denied"))
```

**XSS — t-out siempre, t-raw solo para HTML del sistema:**
```xml
<!-- ❌ NUNCA con datos de usuario -->
<span t-raw="record.description"/>
<!-- ✅ t-out escapa automáticamente -->
<span t-out="record.description"/>
```

**Controllers — auth explícito siempre:**
```python
# ❌ sin auth declarado
@http.route('/api/data', type='json')
# ✅ auth explícito
@http.route('/api/data', type='json', auth='user')
```

**ACL — todo modelo nuevo necesita entrada ir.model.access.csv antes del commit.**

**Regla general**: ante la duda → `knowledge/security/` para el patrón correcto.

---

## Historial de reglas

| Regla | Origen | Fecha |
|-------|--------|-------|
| R13 seguridad | SQL injection, sudo() scope, t-raw→t-out, auth explícito | 2026-05-23 |
| R5 pre-migrate | Descubierto en actualización de vistas XML durante upgrade en módulo v18 | 2026-05-20 |
| R8 sequence_preview con id | Bug de visualización/breadcrumb en secuencia borrador | 2026-05-20 |
| R3 identidad | Verificación contra CONTRIBUTING.md del equipo de desarrollo | 2026-05-15 |
