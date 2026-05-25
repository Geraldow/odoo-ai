---
name: odoo-source
description: >
  Inteligencia completa de un módulo Odoo: analiza manifest, modelos, campos,
  relaciones tipadas, vistas, controllers, flujo frontend→backend (OWL→RPC→Python),
  wizards, seguridad, cron, actions y xpaths. Produce un Module Intelligence Report
  autosuficiente para que el agente pueda escribir herencias o extensiones sin releer el fuente.
  Trigger: /odoo-source {module} | se detecta _inherit | se necesita entender un módulo antes de extenderlo.
license: Apache-2.0
metadata:
  author: Geraldow
  version: "2.0"
---

## When to Use

- El usuario invoca `/odoo-source {module}`
- Se detecta `_inherit = 'model.name'` y se necesita conocer la estructura base
- Se necesita saber qué xpath usar para heredar una vista Enterprise
- Se necesita entender cómo fluyen los datos de la pantalla al backend
- Se necesita conocer controllers, rutas o cómo OWL llama a Python
- Se necesita entender las relaciones, wizards o seguridad del módulo

## Source Paths

```
Enterprise: {EnterprisePath from config.local.yaml}      ← módulos Enterprise (indexado en codesearch alias: enterprise)
Projects:   {ProjectsRoot}\18\{project}\                 ← proyectos custom (indexados en codesearch alias: {project})
```

## Herramienta por contexto de búsqueda

| Contexto | Herramienta | Por qué |
|----------|-------------|---------|
| Buscar patrón en múltiples módulos Enterprise | **codesearch MCP** (search tool, `repo: "enterprise"`) | ~94% menos tokens vs Grep sobre 677 módulos |
| Leer archivo específico de path conocido | **Read tool** | Más directo que codesearch para 1 archivo |
| Buscar patrón dentro de un módulo ya localizado | **Grep/Glob** (bounded al folder del módulo) | Eficiente para búsquedas acotadas |

---

## Workflow — 10 Pasos

### Paso 1 — Verificar y localizar módulo

```
# 1. Buscar en Enterprise con codesearch (más rápido que explorar filesystem)
Use codesearch search tool:
  query: "{module}"
  repo: "enterprise"

# 2. Confirmar path exacto con PowerShell
Test-Path "{EnterprisePath from config.local.yaml}\{module}"
Test-Path "{ProjectsRoot}\18\{project}\{module}"
```

Si codesearch no encuentra el módulo y Test-Path falla → responder con nombre exacto del directorio esperado.

---

### Paso 2 — Manifest

```
Read: {module_path}/__manifest__.py
```

Extraer: `name`, `version`, `license`, `depends`, archivos en `data`, archivos en `demo`, `installable`.

---

### Paso 3 — Modelos y Campos

```
Glob: {module_path}/models/**/*.py
Grep pattern: "_name\s*=|_inherit\s*=|_inherits\s*=|fields\."
path: {module_path}/models/
```

Para cada modelo extraer:
- `_name` → nombre técnico del modelo → tabla PostgreSQL (`.` → `_`)
- `_inherit` / `_inherits` → qué hereda
- Campos por tipo: `Char`, `Integer`, `Float`, `Boolean`, `Date`, `Datetime`, `Text`, `Html`, `Binary`, `Selection`, `Many2one`, `One2many`, `Many2many`, `Monetary`, `Json`
- Campos computed: `compute=`, `store=`, `depends=`
- Campos related: `related=`

> **Módulos grandes** (account, sale, mrp, stock, hr): usar SOLO Grep, nunca Read completo.
> **Módulos pequeños** (<5 archivos Python): Read completo es aceptable.

---

### Paso 4 — Relaciones Tipadas

Para cada campo relacional encontrado, documentar:

| Campo | Tipo | Modelo destino | Inversa / Tabla M2M |
|-------|------|----------------|----------------------|
| `partner_id` | Many2one | `res.partner` | — |
| `order_line` | One2many | `sale.order.line` | `order_id` (campo inverso) |
| `tag_ids` | Many2many | `crm.tag` | tabla: `crm_tag_sale_order_rel` |

Grep para extraer comodel_name e inverse_name:
```
Grep pattern: "comodel_name|inverse_name|relation="
path: {module_path}/models/
```

---

### Paso 5 — Vistas

```
Glob: {module_path}/views/**/*.xml
```

Para cada XML, leer solo primeras 80 líneas (`limit: 80`).

Extraer: `id`, `model`, `inherit_id`, tipo (`form`/`list`/`search`/`kanban`/`pivot`/`graph`/`dashboard`), primeros elementos del `arch`.

Para xpaths exactos: leer la sección específica con `offset` y `limit` apropiados.

---

### Paso 6 — Controllers y Rutas

```
Glob: {module_path}/controllers/**/*.py
Grep pattern: "@http\.route|route=|auth=|type="
path: {module_path}/controllers/
```

Para cada route extraer:

| Ruta URL | Método HTTP | Tipo | Auth | Función Python |
|----------|-------------|------|------|----------------|
| `/pos/web` | GET | http | public | `pos_index()` |
| `/web/pos/session` | POST | jsonrpc | user | `get_pos_ui_config()` |

---

### Paso 7 — Flujo Frontend → Backend (OWL → Python)

```
Glob: {module_path}/static/src/**/*.js
Glob: {module_path}/static/src/**/*.xml
Grep pattern: "orm\.call|this\.orm|jsonRpc|useService|rpc\(|callKw|web_save"
path: {module_path}/static/
```

Mapear la cadena completa:

```
OWL Component         →   RPC Call                          →   Python Model/Método
──────────────────────────────────────────────────────────────────────────────────
PaymentScreen.js      →   orm.call('pos.order',             →   pos.order.action_pos_pos_form()
                           'action_pos_pos_form', [])
ProductScreen.js      →   orm.call('product.product',       →   product.product.get_product_info_pos()
                           'get_product_info_pos', [])
```

**Tipos de llamadas RPC a detectar:**
- `this.orm.call(model, method, args)` → llama directamente a método Python del modelo
- `this.orm.read(model, ids, fields)` → `model.read()`
- `this.orm.write(model, ids, vals)` → `model.write()`
- `this.orm.create(model, vals)` → `model.create()`
- `this.orm.searchRead(...)` → `model.search_read()`
- `jsonRpc('/web/dataset/call_kw', ...)` → llamada genérica al ORM
- Rutas custom vía `fetch('/custom/route')` → buscar en controllers

Si el módulo no tiene archivos JS en `static/`: indicar "módulo sin frontend custom".

---

### Paso 8 — Wizards (TransientModel)

```
Grep pattern: "TransientModel"
path: {module_path}/
```

Para cada wizard encontrado:
- Nombre del modelo (`_name`)
- Campos que recibe
- Método principal de acción (generalmente `action_*`)
- Qué vista lo invoca o qué botón lo abre

---

### Paso 9 — Seguridad

```
Read: {module_path}/security/ir.model.access.csv
Glob: {module_path}/security/*.xml
```

Extraer:
- Grupos definidos en el módulo
- Modelos con acceso CRUD por grupo
- Record rules (`ir.rule`) si existen

---

### Paso 10 — Cron, Actions y Data

```
Glob: {module_path}/data/**/*.xml
Grep pattern: "ir\.cron|ir\.actions\.|automated\.action"
path: {module_path}/
```

Extraer:
- Cron jobs: nombre, modelo, método, intervalo
- Actions definidas: `ir.actions.act_window`, `ir.actions.server`
- Registros de data importantes (configuración, categorías, etc.)

---

## Output: Module Intelligence Report

```markdown
## Module Intelligence Report: {module}
📁 {module_path}
🔖 Odoo {version} | Licencia: {license}

---

### 1. Manifest
- **Nombre**: {name}
- **Versión módulo**: {module_version}
- **Depende de**: {dep1}, {dep2}, ...
- **Data files**: {count} | **Demo**: {count}

---

### 2. Modelos

| Modelo (_name) | Hereda de | Tabla PostgreSQL |
|----------------|-----------|-----------------|
| pos.order | — | pos_order |
| pos.session | — | pos_session |

---

### 3. Campos por Modelo

**{model_name}**
| Campo | Tipo | Info extra |
|-------|------|------------|
| name | Char | required, readonly |
| state | Selection | draft/paid/done/invoiced |
| amount_total | Monetary | compute=_compute_amount_all, store=True |
| partner_id | Many2one | → res.partner |
| lines | One2many | → pos.order.line [order_id] |
| tag_ids | Many2many | → crm.tag |

---

### 4. Relaciones Completas

| Campo | Tipo | Modelo origen | Modelo destino | Inversa / Tabla |
|-------|------|---------------|----------------|-----------------|
| partner_id | M2O | pos.order | res.partner | — |
| lines | O2M | pos.order | pos.order.line | order_id |
| tag_ids | M2M | pos.order | crm.tag | pos_order_crm_tag_rel |

---

### 5. Vistas

| ID XML | Modelo | Tipo | Hereda de |
|--------|--------|------|-----------|
| pos.view_pos_pos_form | pos.order | form | — |
| pos.view_pos_pos_list | pos.order | list | — |

---

### 6. Controllers y Rutas

| Ruta | Método | Tipo | Auth | Handler Python |
|------|--------|------|------|----------------|
| /pos/web | GET | http | public | pos_index() |
| /pos/ui | GET | http | user | pos_ui() |

---

### 7. Flujo Frontend → Backend

| Componente OWL | Llamada RPC | Método Python |
|----------------|-------------|---------------|
| PaymentScreen | orm.call('pos.order', 'action_pos_pos_form') | pos.order.action_pos_pos_form() |
| ProductScreen | orm.call('product.product', 'get_product_info_pos') | product.product.get_product_info_pos() |

---

### 8. Wizards

| Modelo | Campos clave | Acción principal | Invocado desde |
|--------|-------------|-----------------|----------------|
| pos.make.payment | amount, payment_method_id | action_pay() | PaymentScreen.js |

---

### 9. Seguridad

| Grupo | Modelos con acceso |
|-------|--------------------|
| point_of_sale.group_pos_user | pos.order (CRUD), pos.session (R) |
| point_of_sale.group_pos_manager | pos.order (CRUD), pos.session (CRUD) |

---

### 10. Cron & Actions

| Tipo | Nombre | Modelo | Método |
|------|--------|--------|--------|
| ir.cron | Cierre sesión POS | pos.session | action_pos_session_closing_control() |

---

### Xpaths disponibles

{Xpaths exactos basados en el arch real leído del source. Nunca inferir.}

Ejemplo:
```xml
<!-- Agregar campo después de partner_id en form de pos.order -->
<xpath expr="//field[@name='partner_id']" position="after">
  <field name="mi_campo"/>
</xpath>
```
```

---

---

### Paso 11 — Guardar en Engram (OBLIGATORIO — siempre el último paso)

Después de producir el Module Intelligence Report, guardar SIEMPRE en engram:

```
mem_save(
  title:     "odoo/module/{module}/intelligence",
  topic_key: "odoo/module/{module}/intelligence",
  type:      "architecture",
  content:   {Module Intelligence Report completo — los 10 pasos}
)
```

**Si se encontraron errores durante el análisis** (módulo no encontrado, archivo corrupto, patrón inesperado):

```
mem_save(
  title:     "odoo/error/{short-description}",
  topic_key: "odoo/error/{short-description}",
  type:      "bug",
  content:   "Error: {mensaje}\nArchivo: {path}\nCausa: {raíz}\nSolución: {fix}\nContexto: módulo {module}, Odoo {version}"
)
```

**Si se descubrió algo no visto antes** (patrón inusual, API no documentada, comportamiento inesperado):

```
mem_save(
  title:     "odoo/discovery/{topic}",
  topic_key: "odoo/discovery/{topic}",
  type:      "discovery",
  content:   {descripción del descubrimiento, contexto, implicaciones}
)
```

> **Regla**: Nunca terminar odoo-source sin haber llamado mem_save con el Module Intelligence Report.

---

## Critical Patterns

- **NUNCA** modificar archivos del source — solo lectura
- **SIEMPRE** usar PowerShell para verificar si el módulo existe
- **SIEMPRE** usar Grep antes de Read en módulos con más de 5 archivos Python
- Para un **xpath exacto**: leer el XML real, nunca inferir
- Si el módulo tiene `wizard/` o `controllers/`: SIEMPRE incluirlos en el Report
- El Module Intelligence Report debe ser **autosuficiente**: el agente puede usarlo sin releer el source
- Si no hay JS en `static/`: indicar explícitamente "módulo sin frontend custom"

## Commands

```powershell
# Verificar módulo existe (Enterprise)
Test-Path "{EnterprisePath from config.local.yaml}\{module}"

# Verificar módulo existe (proyecto custom)
Test-Path "{ProjectsRoot}\18\{project}\{module}"
```

```
# Listar / buscar módulos Enterprise → codesearch MCP (no usar ls sobre 677 módulos)
Use codesearch search tool:
  query: "{module_name_or_keyword}"
  repo: "enterprise"

# Buscar patrón en todos los módulos Enterprise
Use codesearch search tool:
  query: "{pattern}"        # ej: "_inherit = 'account.move'"
  repo: "enterprise"

# Buscar en proyecto custom específico
Use codesearch search tool:
  query: "{pattern}"
  repo: "{project}"         # ej: "intiflow", "aeca", "conservial"
```

## Resources

- **Source Enterprise**: `{EnterprisePath from config.local.yaml}` — módulos Enterprise (alias codesearch: `enterprise`)
- **Proyectos custom**: `{ProjectsRoot}\18\{project}\` (aliases: `intiflow`, `aeca`, `conservial`, `omnia`)
