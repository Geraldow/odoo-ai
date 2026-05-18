---
name: skill-evolver
description: Detecta patrones nuevos que emergen durante sesiones de trabajo, los clasifica al skill/script correcto, genera el cambio mínimo para automatizarlos, y los aplica con confirmación explícita del usuario. Agnóstico al dominio.
triggers:
  - /skill-evolve
---

## Trigger

Invocado con:
```
/skill-evolve <descripción del patrón en lenguaje natural>
```

Ejemplos:
- `/skill-evolve "si existe custom_addons/, montar solo ese directorio en Docker"`
- `/skill-evolve "si el host termina en .odoo.com, usar flujo SSH remoto"`
- `/skill-evolve "si vite.config.ts existe, no sugerir webpack"`

---

## Fase 1 — Verificar duplicados

Antes de clasificar, ejecutar:
```
mem_search("skill-evolver/applied {palabras clave del patrón}")
```

Si existe coincidencia con similitud alta:
> "Encontré un patrón similar ya automatizado:
>   topic_key: skill-evolver/applied/{slug}
>   archivo: {ruta}
>   fecha: {fecha}
>
> ¿Desea ver el patrón existente o continuar con uno nuevo? (ver/nuevo)"

- `ver` → mostrar contenido del engram y detenerse
- `nuevo` → continuar a Fase 2

---

## Fase 2 — Clasificación por dominio

Leer los skills disponibles en `~/.claude/skills/` y clasificar el patrón según la tabla:

| Dominio | Palabras clave | Skill destino | Archivo destino |
|---|---|---|---|
| **infra/Docker** | docker, volumen, compose, port, mount, container, imagen, custom_addons | odoo-contribute | scripts/docker-setup.ps1 |
| **git/VCS** | git, branch, commit, PR, tag, merge, cherry-pick, push, rebase | odoo-contribute | scripts/branch-safety-check.ps1 |
| **detección de entorno** | entorno, local, cloud, Odoo.sh, host, remoto, SSH detect | odoo-contribute | scripts/detect-environment.ps1 |
| **Odoo — versión/manifest** | manifest, versión, edition, Community, Enterprise, LGPL, OEEL | odoo-development | scripts/odoo-version-detect.ps1 |
| **Odoo — análisis de módulo** | módulo, modelo, campo, vista, ORM, inherit, security, access | odoo-development | scripts/module-intelligence.ps1 |
| **Frontend** | React, Vite, Node, TypeScript, webpack, npm, pnpm, vite.config | (skill nuevo si no existe) | nuevo SKILL.md |
| **CI/CD** | GitHub Actions, pipeline, workflow, lint, test runner, release, deploy | odoo-contribute | plugins/odoo-ci/SKILL.md |
| **ops/SSH** | SSH, backup, DB dump, sftp, rsync, conexión remota, restore | odoo-contribute | plugins/odoo-ops/SKILL.md |
| **API externa** | API, rate limit, OAuth, token, webhook, retry, auth header | (skill nuevo si no existe) | nuevo SKILL.md |
| **Sin categoría clara** | — | Preguntar al usuario | — |

Si el dominio no coincide → preguntar:
> "No pude clasificar este patrón automáticamente. ¿A qué área pertenece? (Docker / git / Odoo / frontend / CI/CD / ops / API / otro)"

### Si el skill destino no existe

Verificar si `~/.claude/skills/{nombre}/` existe. Si no:
> "El skill destino '{nombre}' no existe aún.
> Propongo crear:
>   ~/.claude/skills/{nombre}/
>   └── SKILL.md  (estructura mínima)
>
> ¿Crear la estructura? (sí/no)"

Estructura mínima del SKILL.md propuesto:
```markdown
---
name: {nombre}
description: {descripción inferida del patrón}
---

## Trigger

## Reglas

```

---

## Fase 3 — Determinar scope

Preguntar antes de generar el diff:

> "¿Este patrón aplica a todos los proyectos (global) o solo al proyecto actual ({proyecto})?"
>
> - **global** → modifica el script en `~/.claude/skills/`
> - **proyecto** → registra en engram con scope del proyecto (no modifica scripts globales)

---

## Fase 4 — Mostrar diff, confirmar y aplicar

### 1. Generar el bloque mínimo de código

1. Leer el archivo destino completo con Read tool
2. Identificar el punto exacto de inserción (función, condicional, sección, o final)
3. Generar el bloque mínimo que automatiza el patrón

### 2. Mostrar al usuario

```
Patrón clasificado en: {skill}/{archivo}

Cambio propuesto:
--- a/{archivo relativo}
+++ b/{archivo relativo}
@@ línea X @@
 {contexto: 2 líneas antes}
+{líneas nuevas a agregar}
 {contexto: 2 líneas después}

Scope: {global | proyecto: {nombre}}

¿Aplicar este cambio? (sí/no)
```

### 3. Si el usuario responde `sí`

1. Aplicar con Edit tool
2. Guardar en engram:
   - `topic_key`: `skill-evolver/applied/{slug}`
   - `type`: `feedback`
   - `content`: patrón, archivo modificado, skill destino, scope, fecha, diff aplicado
3. Confirmar:
> "Patrón aplicado y registrado en engram (topic_key: skill-evolver/applied/{slug})."

### 4. Si el usuario responde `no`

1. NO modificar ningún archivo
2. Guardar en engram con type: feedback, indicando rechazo
3. Confirmar: "Entendido. No se realizaron cambios."

---

## Flujo de datos

```
Usuario: /skill-evolve "descripción"
    │
    ▼
[Fase 1] mem_search → ¿duplicado? → notificar → fin
    │ no duplicado
    ▼
[Fase 2] Clasificar por tabla de dominios
    ├── skill existe → continuar
    └── skill no existe → proponer crear → confirmar
    │
    ▼
[Fase 3] Preguntar scope: global | proyecto
    │
    ▼
[Fase 4] Read archivo → generar diff → mostrar → ¿sí?
    ├── sí → Edit → mem_save(applied/{slug}) → confirmar
    └── no → mem_save(rejected/{slug}) → confirmar sin cambios
```

---

## Reglas de oro

- NUNCA aplicar sin confirmación explícita `sí`
- SIEMPRE buscar en engram al inicio para detectar duplicados
- Si el skill destino no existe → proponer estructura mínima, NO crearla sin confirmación
- Patrón muy específico de 1 proyecto → recomendar scope proyecto en lugar de global
- El árbol de clasificación es extensible: nuevo dominio recurrente = nueva fila en la tabla
