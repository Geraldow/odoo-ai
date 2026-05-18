---
name: odoo-contribute
description: Hub VCS, git, infraestructura, Docker, OCA. Orquesta auto-detection en paralelo, carga plugins especializados.
license: MIT
metadata:
  author: Geraldow
  version: "1.4"
---

## Inicialización — Auto-Detection (PARALELO + SECUENCIAL)

### Fase 1: Auto-Detection (PARALELO)

Ejecutar en paralelo:
- `scripts/detect-environment.ps1` → Odoo.sh vs local/Docker status
- `scripts/branch-safety-check.ps1` → rama actual, ramas remotas, validación

Esperar a que ambos completen.

### Fase 2: Interpretación (SECUENCIAL)

Según resultado de detect-environment:

**SI ODOO_SH:**
- Proceder con contexto remoto
- No necesita Docker

**SI LOCAL_DEV:**
- `scripts/docker-setup.ps1` → verificar/iniciar Docker
- Proceder con contexto local

### Fase 3: Clasificación (SEGÚN CONTEXTO)

Detectar necesidad del usuario usando tabla abajo → cargar plugin hijo correspondiente

> Base: `~/.claude/skills/odoo-contribute/` (Windows: `C:\Users\fairg\.claude\skills\odoo-contribute\`)

---

## Tabla de Detección

| Contexto | Plugin | Script | Leer |
|----------|--------|--------|------|
| Detectar Odoo.sh vs local Docker | — | `scripts/detect-environment.ps1` | — |
| Branch safety, rama actual, ramas remotas | — | `scripts/branch-safety-check.ps1` | — |
| Docker setup, docker-compose | — | `scripts/docker-setup.ps1` | — |
| Git commit, "commitea", "sube" | odoo-commit | — | `plugins/odoo-commit/SKILL.md` |
| PR, MR, pull request | odoo-pr | — | `plugins/odoo-pr/SKILL.md` |
| Changelog, CHANGELOG | odoo-changelog | — | `plugins/odoo-changelog/SKILL.md` |
| CI, GitHub Actions, pipeline | odoo-ci | — | `plugins/odoo-ci/SKILL.md` |
| Nuevo módulo, estructura | odoo-module | — | `plugins/odoo-module/SKILL.md` |
| OCA standards, pre-commit | odoo-oca | — | `plugins/odoo-oca/SKILL.md` |
| SSH, DB, psql, backup, logs | odoo-ops | — | `plugins/odoo-ops/SKILL.md` |
| Orientación Odoo, stack, arquitectura | odoo-overview | — | `plugins/odoo-overview/SKILL.md` |

---

## Critical Rules

- **Scripts primero** — ejecutar script antes de leer plugin
- **Trigger explícito** — solo leer plugin si usuario lo pide o contexto lo requiere
- **Branch safety** → ejecutar `scripts/branch-safety-check.ps1` ANTES de push/commit
- **No "Co-Authored-By"** — commits convencionales solo
- Confirmar antes de push (acción irreversible)

---

## Scripts Disponibles

- `detect-environment.ps1` — Odoo.sh vs local; Docker status
- `branch-safety-check.ps1` — rama actual, ramas remotas, validación
- `docker-setup.ps1` — verificar Docker, iniciar containers
