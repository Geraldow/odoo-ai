---
name: odoo-ops
description: >
  Operaciones seguras SSH y de base de datos para servidores Odoo y Odoo.sh.
  Incluye resolución automática de URLs SSH de Odoo.sh (que cambian por rebuild)
  y guardrails contra queries destructivos.
  Trigger: conexión SSH a servidor Odoo, queries PostgreSQL, administración
  de instancia, verificar logs, reiniciar servicios.
license: MIT
metadata:
  author: Geraldow
  version: "2.0"
---

## When to Use

- Conectar a un servidor Odoo vía SSH (incluyendo Odoo.sh)
- Ejecutar queries contra la base de datos PostgreSQL de Odoo
- Verificar logs, reiniciar servicios, gestionar instancias Odoo
- Analizar estado de la base de datos (registros, configuración, módulos instalados)

---

## Odoo.sh SSH URL Resolution Protocol

Las URLs SSH de Odoo.sh cambian con cada rebuild. Formato:

```
ssh {build_id}@{project}-{branch}-{build_id}.dev.odoo.com
```

Ejemplo real: `ssh 32222469@wong-st-produccion-32222469.dev.odoo.com`

### Paso 1 — Buscar en known_hosts (más rápido)

```bash
grep "dev.odoo.com" ~/.ssh/known_hosts | awk '{print $1}' | tr ',' '\n' | grep "dev.odoo.com" | sort -u
```

Esto lista todos los hosts Odoo.sh con los que se ha conectado antes. Filtra por rama:

```bash
# Ejemplo: filtrar por rama st_produccion del proyecto wong
grep "wong-st-produccion" ~/.ssh/known_hosts | awk '{print $1}' | tr ',' '\n' | sort -u | tail -1
```

> **Limitación**: `known_hosts` conserva entradas antiguas. El build_id más reciente es el válido.
> Si hay varias entradas para la misma rama, usar la de mayor build_id numérico.

### Paso 2 — Detectar desde la instancia activa (si ya hay sesión SSH)

Si el usuario ya está conectado a cualquier instancia Odoo.sh:

```bash
# Ver el hostname de la instancia actual
echo $HOSTNAME
# → wong-st-produccion-32222469.dev.odoo.com

# Variables de entorno del build
env | grep -iE "(ODOO|BUILD|STAGE|BRANCH|INSTANCE)" 2>/dev/null

# Config de la instancia (puede revelar datos útiles)
cat /home/odoo/.profile 2>/dev/null | grep -iE "(url|host|build)"
cat /etc/environment 2>/dev/null
```

Extraer componentes del hostname para reconstruir otras URLs:

```bash
# El hostname tiene el formato: {project}-{branch}-{build_id}.dev.odoo.com
HOSTNAME_CLEAN=$(echo $HOSTNAME | sed 's/.dev.odoo.com//')
# → wong-st-produccion-32222469

BUILD_ID=$(echo $HOSTNAME_CLEAN | rev | cut -d'-' -f1 | rev)
# → 32222469

PROJECT=$(echo $HOSTNAME_CLEAN | cut -d'-' -f1)
# → wong
```

> **Nota**: Desde una instancia de producción NO se puede obtener el build_id de staging.
> Cada instancia es aislada. Solo se puede saber su propio hostname.

### Paso 3 — Cache local de URLs activas

Guardar URLs conocidas en un archivo de cache para reutilizar:

```bash
# Guardar una URL conocida (el usuario la proporciona desde el dashboard)
echo "st_produccion: ssh 32222469@wong-st-produccion-32222469.dev.odoo.com" >> ~/.odoo-sh-urls

# Leer el cache
cat ~/.odoo-sh-urls 2>/dev/null
```

Cuando el usuario proporcione una URL nueva, actualizar el cache:

```bash
# Reemplazar entrada existente de la rama
BRANCH="st_produccion"
NEW_URL="ssh 32222469@wong-st-produccion-32222469.dev.odoo.com"

# Eliminar entrada anterior de esa rama y agregar la nueva
grep -v "^$BRANCH:" ~/.odoo-sh-urls > /tmp/.odoo-sh-urls-tmp 2>/dev/null
echo "$BRANCH: $NEW_URL" >> /tmp/.odoo-sh-urls-tmp
mv /tmp/.odoo-sh-urls-tmp ~/.odoo-sh-urls
```

### Paso 4 — Fallback: Obtener desde el Dashboard

Si los pasos anteriores no dan resultado, indicar al usuario:

```
Para obtener la URL SSH actual de la rama {rama}:
1. Ir a https://odoo.sh → Proyecto → Branches
2. Clic en la rama deseada
3. En el panel derecho → tab "SSH"
4. Copiar la URL que aparece (formato: ssh {id}@{proyecto}-{rama}-{id}.dev.odoo.com)
```

### Regla de Resolución (orden de prioridad)

```text
1. Cache (~/.odoo-sh-urls)       → más rápido, usuario lo actualizó manualmente
2. $HOSTNAME dentro de instancia → solo sirve para la rama actual
3. known_hosts + build_id mayor  → puede estar desactualizado si hubo rebuild reciente
4. Pedir al usuario (dashboard)  → siempre confiable
```

---

## SSH Workflow

1. Ejecutar el **Odoo.sh SSH URL Resolution Protocol** si el destino es Odoo.sh (`.dev.odoo.com`)
2. Para servidores propios (VPS, on-premise), usar `~/.ssh/config` si está disponible
3. Nunca almacenar contraseñas en texto plano — usar SSH keys siempre
4. Operar como usuario del servicio `odoo`, no como `root` ni `postgres` directamente

## File Transfer from Odoo.sh

**Odoo.sh no expone SFTP.** `scp` y `rsync` fallan con `subsystem request failed on channel 0`.

### Único método válido — SSH + tar pipe

```bash
# Descargar módulo(s) específicos
ssh USER@INSTANCE.odoo.com "tar czf - -C /home/odoo/src modulo_a modulo_b" \
  | tar xzf - -C /ruta/local/destino/

# Descargar directorio completo (ej: enterprise)
ssh USER@INSTANCE.odoo.com "tar czf - -C /home/odoo/src enterprise" \
  | tar xzf - -C /ruta/local/destino/

# Leer archivo único (sin descarga)
ssh USER@INSTANCE.odoo.com "cat /home/odoo/src/user/modulo/__manifest__.py"
```

### Paths estándar en Odoo.sh

```
/home/odoo/src/
├── odoo/        ← Community source
├── enterprise/  ← Enterprise source
└── user/        ← Custom modules del proyecto
```

---

## Database Query Rules

### PERMITIDO sin confirmación (solo lectura)

```sql
SELECT ...
EXPLAIN ...
\d tablename    -- describir estructura de tabla
\dt             -- listar tablas
\du             -- listar usuarios de PostgreSQL
```

### REQUIERE CONFIRMACIÓN EXPLÍCITA

```sql
UPDATE ...      -- mostrar preview de filas afectadas primero
DELETE ...      -- mostrar conteo de filas afectadas primero
INSERT ...      -- mostrar qué se va a insertar
ALTER TABLE ... -- mostrar el cambio estructural
```

### BLOQUEADO — nunca ejecutar sin que el usuario escriba el comando exacto

```sql
DROP TABLE ...
DROP DATABASE ...
TRUNCATE ...
DELETE FROM ... (sin cláusula WHERE)
UPDATE ...      (sin cláusula WHERE)
```

## Guardrail Protocol

Antes de ejecutar cualquier query no-SELECT:

1. Mostrar la query completa al usuario
2. Mostrar el impacto estimado (conteo de filas, tabla afectada)
3. Pedir confirmación explícita: **"¿Confirmas ejecutar esta operación? (sí/no)"**
4. Solo proceder tras confirmación — ante la duda, no ejecutar

## Common Operations

### Verificar procesos Odoo activos

```bash
ps aux | grep odoo
systemctl status odoo
```

### Ver logs recientes

```bash
tail -f /var/log/odoo/odoo.log
journalctl -u odoo -n 100
```

### Reiniciar servicio Odoo

```bash
sudo systemctl restart odoo
```

### Conectar a PostgreSQL como usuario odoo

```bash
psql -U odoo -d {nombre_base_de_datos}
```

### Verificar estado de un módulo

```sql
SELECT name, state, latest_version
FROM ir_module_module
WHERE name = 'nombre_del_modulo';
```

### Listar módulos instalados

```sql
SELECT name, latest_version, state
FROM ir_module_module
WHERE state = 'installed'
ORDER BY name;
```

### Verificar tamaño de base de datos

```sql
SELECT pg_size_pretty(pg_database_size(current_database()));
```

### Buscar registros huérfanos de un modelo

```sql
SELECT COUNT(*) FROM {tabla}
WHERE id NOT IN (SELECT res_id FROM ir_model_data WHERE model = '{model.name}');
```

## Data Privacy Protocol — Ley 29733 (Perú)

Al acceder vía SSH a cualquier servidor Odoo con datos de clientes:

1. **NUNCA guardar en engram**: nombres, RUC, DNI, emails, transacciones, nóminas, PII de cualquier tipo
2. **NUNCA incluir** datos de clientes en commits, PRs, comentarios de código o mensajes
3. **Usar los datos SOLO** para la tarea inmediata — no retenerlos entre sesiones
4. **Si debes referenciar** un dato, enmascararlo:
   - RUC → `20XXXXXXX12`
   - Email → `u***@dominio.com`
   - Nombre → `Cliente X`
5. **Ante datos financieros** (saldos, pagos, facturas) → confirmar con el usuario antes de mostrar

> Aplica incluso en staging/desarrollo si contiene datos migrados de producción.

---

## Critical Rules

1. NUNCA ejecutar como `postgres` o `root` sin confirmación explícita del usuario
2. NUNCA ejecutar queries destructivos sin mostrar el impacto estimado primero
3. SIEMPRE verificar cláusula `WHERE` antes de `UPDATE` o `DELETE`
4. Ante la duda, preguntar — el costo de preguntar es bajo, el de un error es irreversible
5. No modificar datos de producción en horario de uso activo sin coordinación previa
