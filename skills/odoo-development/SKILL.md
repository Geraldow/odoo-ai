---
name: odoo-development
description: Hub central ORM, modelos, vistas, seguridad, testing, E2E. Auto-detección de versión, análisis módulo, contexto → plugin.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.2"
---

## Inicialización — Auto-Detection (PARALELO + SECUENCIAL)

### Fase 1: Auto-Detection (PARALELO)

Ejecutar en paralelo:
- `scripts/odoo-version-detect.ps1` → versión Odoo, edition (Community/Enterprise), module name
- `scripts/module-intelligence.ps1` → análisis 10 pasos (modelos, vistas, controllers, seguridad, etc)

Esperar a que ambos completen.

### Fase 2: Validación (SECUENCIAL)

- Si versión < 18: ⚠️ advertir sobre deprecaciones versión anterior
- Si edition = Enterprise: cargar plugins Enterprise (diferentes APIs)
- Si módulo falta ACL: ⚠️ advertir sobre seguridad incompleta

### Fase 3: Clasificación (SEGÚN CONTEXTO)

Detectar necesidad del usuario usando tabla abajo → cargar plugin hijo

> Plugins base: `~/.claude/skills/odoo-development/plugins/`

---

## Tabla de Detección (Contexto → Plugin)

*Nota: `odoo-version-detect.ps1` y `module-intelligence.ps1` se ejecutan automáticamente en Fase 1. Usar tabla solo para contexto adicional del usuario.*

| Necesitas | Plugin | 
|-----------|--------|
| Explorar módulo profundamente: flujo OWL→backend, wizards, cron, xpaths | odoo-source |
| Snippets por dominio: accounting, stock, HR, computed, onchange, cron | fhidalgo |
| Templates módulo completo, boilerplate | fhidalgo |
| E2E completo (no Playwright) | fhidalgo |
| Code review checklist OCA | fhidalgo |
| Validar xpath en vista | view-xpath-validator (script) |
| Análisis upgrade/migrate | fhidalgo |
| Referencia ORM profunda v18 | unclecatvn | — |
| Referencia campos v18 | unclecatvn | — |
| Referencia decoradores v18 | unclecatvn | — |
| Referencia OWL 2.x v18 | unclecatvn | — |
| Referencia seguridad v18 | unclecatvn | — |
| Referencia performance v18 | unclecatvn | — |
| Referencia controllers HTTP v18 | unclecatvn | — |
| E2E Playwright odoo-ui | maingocdoan | — |
| Rellenar campos complejos Playwright | maingocdoan | — |
| Generador tests automático | ahmedlakos | — |
| Logs Docker, diagnóstico 500/arranque, troubleshooting | ahmedlakos — `odoo-docker-plugin/reference/troubleshooting.md` |
| Inicializar DB, `-i base`, `--stop-after-init`, flags server | ahmedlakos — `odoo-service-plugin/memories/server_commands.md` |
| Docker deployment general | ahmedlakos | — |
| Temas, SCSS, Figma→tema | ahmedlakos | — |
| i18n: traducción, extracción | ahmedlakos | — |
| Reportes QWeb PDF | ahmedlakos | — |
| ir.actions.server, ir.actions.act_window | peterurban | — |
| ir.cron avanzado | peterurban | — |
| Patrones accounting v18 | peterurban | — |
| Patrones sales v18 | peterurban | — |
| Validar identidad contribuidor del equipo | — | Ver `~/.claude/skills/odoo-development/CONTRIBUTING.md` (local, generado por el equipo durante setup) |

---

## Critical Rules

- **Branch Safety PRIMERO** — siempre ejecutar branch-safety-check.ps1
- **Odoo version SEGUNDO** — ejecutar odoo-version-detect.ps1 (obligatorio)
- **Plugin correcto TERCERO** — seleccionar por contexto
- **Enterprise source CUARTO (sdd-design)** — para cada API de Odoo en el diseño (manifest key, hook signature, decorador, campo, XML), usar el **codesearch MCP search tool** con `repo: "enterprise"` para encontrar el formato exacto. Nunca asumir — siempre verificar. Source: `C:\Development\Odoo\18\Source\enterprise\` (43.931 chunks indexados).
- **No inline code** — siempre de snippets/templates de plugins
- **OCA standards** — aplicar siempre para cualquier código nuevo

> **Búsquedas en Enterprise source**: **codesearch MCP primero** → Grep acotado al módulo → Read archivo específico.
> El codesearch reduce ~94% el consumo de tokens versus Grep directo sobre 677 módulos.

---

## Scripts Disponibles

- `odoo-version-detect.ps1` — Lee `__manifest__.py`, extrae versión y edition
- `module-intelligence.ps1` — Análisis completo de módulo (10 pasos)
- `view-xpath-validator.ps1` — Valida xpath en XML antes de guardar
- `test-runner.ps1` — Ejecuta tests del módulo en Docker
