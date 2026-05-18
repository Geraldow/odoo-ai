---
name: odoo-development-alesco
description: >
  Plugin de desarrollo Odoo propio de Alesco Perú. Gestiona autorización de contribuidores,
  verificación de identidad antes de commits, y sirve como referencia de proyectos en scope.
  Trigger: inicio de sesión de desarrollo, antes de cualquier commit, verificación de identidad.
license: LGPL-3
metadata:
  author: Geraldow
  version: "1.0.0"
  org: Alesco-Peru
---

## Propósito

Este plugin es la capa de seguridad de desarrollo para proyectos Alesco Perú. Define quién puede contribuir, cómo verificarlo, y qué proyectos están en scope.

## INITIALIZATION — Ejecutar al cargar

1. Leer `CONTRIBUTING.md` (en este mismo directorio) para cargar la lista de contribuidores autorizados
2. Verificar identidad activa:
   ```bash
   git config user.name
   git config user.email
   gh api user --jq '{login, name, email}'
   ```
3. Cruzar contra la lista de contribuidores — si NO coincide → **DETENER y alertar**
4. Si coincide → confirmar al usuario: "Identidad verificada: {nombre} ({github})"

## Verificación de identidad

Ver protocolo completo en [`CONTRIBUTING.md`](CONTRIBUTING.md).

Un committer es válido si su `user.email` O `user.name` O GitHub login coincide con cualquier entrada en la lista de contribuidores autorizados.

## Cuándo cargar este plugin

- Al iniciar cualquier sesión de desarrollo en un proyecto Alesco
- Antes de ejecutar `git commit` (verificación automática)
- Cuando el orquestador necesita confirmar si el usuario actual puede contribuir
