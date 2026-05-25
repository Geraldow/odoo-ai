# Changelog - Odoo-AI

Todos los cambios notables de este proyecto se documentarán en este archivo, siguiendo el formato de [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [3.0] - 2026-05-25

### Añadido
- `RULES.md`: Archivo maestro de reglas para el desarrollo de Odoo (detección de versión, seguridad de ramas, seguridad, estándares de código y cumplimiento de SDD). Formato de plantilla que los equipos pueden personalizar en el momento de la instalación.
- `config.local.yaml.template`: Plantilla de configuración para rutas locales.
- Nuevos directorios para la base de conocimientos autónoma: `knowledge/agents/`, `knowledge/api/`, `knowledge/alesco/` (generado por el equipo), `knowledge/business/`, `knowledge/core/`, `knowledge/debugging/`, `knowledge/devops/`, `knowledge/migration/`, `knowledge/patterns/`, `knowledge/security/` y `knowledge/testing/`.

### Cambiado
- **[CRÍTICO / BREAKING]** Renombrado del directorio de la skill de `skills/odoo-development/` a `skills/odoo-ai/`. El script `install.ps1` gestiona este cambio automáticamente al reinstalar.
- **[NUEVA ARQUITECTURA]** Reemplazo del sistema de plugins externos de la comunidad por una estructura de directorios `knowledge/` autocontenida, evitando la descarga de 5 repositorios externos independientes.
- Reubicación de los plugins de la comunidad (`ahmedlakos`, `fhidalgo`, `maingocdoan`, `peterurban`, `unclecatvn`) a `skills/archived/`, preservados únicamente para referencia y ya no se actualizan automáticamente.
- `update.ps1`: Actualizado para descargar directamente del repositorio upstream y reinstalar las skills en lugar de clonar los repositorios de plugins externos.
- Actualización de los metadatos en `SKILL.md` (versión 3.0, autor: Geraldow, licencia: Apache-2.0).
