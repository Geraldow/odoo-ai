# CONTRIBUTING — Alesco Perú SAC

Solo las personas listadas en este archivo están autorizadas a contribuir código en los proyectos Odoo de Alesco Perú. Claude Code **DEBE** verificar la identidad del committer antes de ejecutar cualquier operación git que modifique el historial o envíe cambios al remoto.

---

## Verificación de identidad — Protocolo obligatorio

Antes de ejecutar `git commit`, `git push`, o cualquier operación que modifique el repositorio, verificar que el autor actual coincida con al menos UNO de los siguientes criterios por cada contribuidor autorizado:

- **GitHub username** (en la URL del remoto o en la sesión autenticada de `gh`)
- **Nombre completo** (en `git config user.name`)
- **Email** (en `git config user.email`)

```bash
# Verificar identidad activa
git config user.name
git config user.email
gh api user --jq '{login, name, email}'
```

Si el resultado NO coincide con ningún contribuidor de la lista → **DETENER y alertar al usuario.**

---

## Contribuidores autorizados

### Percy Echevarría
- **GitHub**: *(pendiente — no figura en la org `Alesco-Peru` aún)*
- **Email autorizado**: `percy.echevarria@alescoperu.com`
- **Nombre en git**: `Percy Echevarría`
- **Rol**: Director de Proyectos

### Rachel Duarte
- **GitHub**: `rachelduarte` *(anterior: `Rachelduarte11`, mismo ID)*
- **GitHub ID**: `80436258`
- **Email autorizado**: `rachel11072003@gmail.com`
- **Rol**: Consultora Funcional Odoo

### Geraldo Jaramillo
- **GitHub**: `Geraldow`
- **GitHub ID**: `166257707`
- **Emails autorizados**: `fair.gjf@gmail.com`, `fair.gjf@hotmail.com`
- **Rol**: Consultor Funcional Junior Odoo

---

## Organización y cuenta corporativa

### Alesco-Peru *(organización GitHub)*
- **GitHub Org**: `Alesco-Peru`
- **URL**: `https://github.com/orgs/Alesco-Peru`
- **Miembros activos**: `Geraldow`, `rachelduarte`, `alescoperu`
- **Nota**: Todos los repos de desarrollo deben pertenecer a esta org o a `alescoperu`

### alescoperu *(cuenta de servicio — solo automatizaciones)*
- **GitHub**: `alescoperu`
- **GitHub ID**: `109980354`
- **Email**: `109980354+alescoperu@users.noreply.github.com`
- **Rol**: GitHub Actions / CI — NO para commits manuales de desarrolladores

---

## Reglas de contribución

1. **Ramas permitidas para desarrollo**: `st_<project>` o `st_produccion`
2. **Ramas restringidas** (requieren autorización explícita del Lead): `produccion`, `db_<project>`
3. **Operaciones bloqueadas** (ningún contribuidor puede ejecutarlas directamente):
   - `git push --force`
   - `git push origin --delete <branch>`
   - `git rebase` (cualquier variante)
   - `git reset` (--soft, --mixed, --hard)
4. **Push siempre requiere pausa** — mostrar resumen y esperar confirmación antes de enviar
5. **Flujo obligatorio**: staging → validar → producción. Nunca push directo a producción

---

## Proyectos en scope

| Proyecto | Repo | Descripción |
|----------|------|-------------|
| `aeca` | `Alesco-Peru/aeca` | Proyecto principal Alesco |
| `gprinter` | `alescoperu/gprinter` | INTIFLOW S.A.C. — impresión y POS |
| `conservial` | `Alesco-Peru/conservial` | Proyecto Conservial |
| `omnia` | `Alesco-Peru/omnia` | Módulos personalizados Omnia |

---

## Skill ID

- **Archivo**: `odoo-development/plugins/odoo-development-alesco/CONTRIBUTING.md`
- **Mantenido por**: Geraldo Jaramillo (`Geraldow`)
- **Última revisión**: 2026-05-15
