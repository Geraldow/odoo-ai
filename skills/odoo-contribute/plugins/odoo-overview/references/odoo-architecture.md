# Odoo Architecture Reference

## Official Documentation

| Resource | URL |
|----------|-----|
| Odoo Developer Docs | https://www.odoo.com/documentation/18.0/developer.html |
| Odoo Contributing Guide | https://www.odoo.com/documentation/18.0/contributing/development.html |
| Odoo ORM Reference | https://www.odoo.com/documentation/18.0/developer/reference/backend/orm.html |
| Odoo Views Reference | https://www.odoo.com/documentation/18.0/developer/reference/backend/views.html |
| Odoo Security Reference | https://www.odoo.com/documentation/18.0/developer/reference/backend/security.html |
| Odoo JavaScript (OWL) | https://www.odoo.com/documentation/18.0/developer/reference/frontend/javascript_reference.html |
| Odoo QWeb Templates | https://www.odoo.com/documentation/18.0/developer/reference/frontend/qweb.html |
| OCA Guidelines | https://github.com/OCA/odoo-community.org/blob/master/website/Contribution/CONTRIBUTING.rst |

---

## Source Code Structure

Key directories in the Odoo source:

```text
odoo/
├── odoo/
│   ├── models.py         ← BaseModel, Model, TransientModel, AbstractModel
│   ├── fields.py         ← Field definitions (Char, Integer, Many2one, etc.)
│   ├── api.py            ← Decorators (@api.depends, @api.constrains, etc.)
│   ├── exceptions.py     ← UserError, ValidationError, AccessError
│   ├── http.py           ← Controller, route(), Request
│   ├── tools/            ← Utilities (config, mail, image, etc.)
│   └── addons/
│       ├── base/         ← Core module (res.partner, res.users, ir.*)
│       ├── web/          ← Web client, OWL framework, assets
│       ├── mail/         ← Chatter, messaging, activities
│       └── ...           ← All standard modules
```

---

## Request Lifecycle

```text
Browser Request
    │
    ▼
Werkzeug (WSGI)
    │
    ▼
odoo.http.Root (routing)
    │
    ├── Static file? → Serve directly
    │
    ├── JSON-RPC? → Controller method (type='jsonrpc')
    │
    └── HTTP? → Controller method (type='http')
         │
         ▼
    Controller calls ORM
         │
         ▼
    ORM executes SQL via cursor (cr)
         │
         ▼
    PostgreSQL
```

---

## Development Modes

| Mode | How to Enable | Effect |
|------|--------------|--------|
| Dev mode | `--dev=all` | Auto-reload Python, reload assets, show tracebacks |
| Debug mode | `?debug=1` in URL | Show technical fields, developer menu |
| Debug assets | `?debug=assets` | Unminified JS/CSS for debugging |
| Test mode | `--test-enable` | Run tests after module install |
| Shell | `odoo shell -d mydb` | Interactive Python shell with ORM access |

---

## Configuration (odoo.conf)

Key parameters:

```ini
[options]
; Database
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo
db_name = mydb

; Paths
addons_path = /opt/odoo/odoo/addons,/opt/odoo/custom-addons
data_dir = /opt/odoo/.local/share/Odoo

; Server
http_port = 8069
workers = 4
max_cron_threads = 2

; Logging
log_level = info
log_handler = :INFO

; Security
admin_passwd = admin
list_db = False
```
