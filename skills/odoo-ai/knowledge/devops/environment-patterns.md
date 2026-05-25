---
title: Environment Patterns
domain: devops
version: 18.0
edition: both
source: native
status: active
---

# Environment Patterns

Managing configurations across Development, Staging, and Production.

## .env Files

Use environment variables for sensitive or environment-specific data.

```env
# .env
ODOO_DB_USER=odoo
ODOO_DB_PASSWORD=secret
ODOO_ADMIN_PASSWD=super_secret
ODOO_STAGE=production
```

## odoo.conf Structure

A standard production `odoo.conf`:

```ini
[options]
admin_passwd = $ODOO_ADMIN_PASSWD
db_host = db
db_port = 5432
db_user = $ODOO_DB_USER
db_password = $ODOO_DB_PASSWORD
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons
workers = 5
proxy_mode = True
limit_memory_soft = 2147483648
limit_memory_hard = 2684354560
```

## Multi-Database Setup

- **dbfilter**: Use `%h` or `%d` to automatically route requests to the correct database based on the subdomain.
- **list_db**: Set to `False` in production to prevent users from seeing other databases.

## Developer Mode

- **Standard**: `?debug=1` in the URL.
- **With Assets**: `?debug=assets` (disables minification of JS/CSS).
- **Command Line**: `--dev=all` for auto-reloading and direct feedback.
