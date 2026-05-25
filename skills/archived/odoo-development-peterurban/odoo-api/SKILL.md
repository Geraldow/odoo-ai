---
name: odoo-api
description: Use this skill whenever working with Odoo's external API - JSON-2 or XML-RPC. Triggers include any mention of 'Odoo API', 'JSON-2', 'XML-RPC', 'external API', 'API key', 'bearer auth', 'api.anthropic', '/json/2/', 'execute_kw', 'search_read via API', 'programmatic access to Odoo', or when writing Python scripts that call Odoo remotely (not server actions). Also use when the user asks about creating fields/views/rules programmatically via API, file upload/download via ir.attachment, or running server actions from external scripts. Do NOT use for server actions running inside Odoo (use odoo-server-actions skill instead) or for general Odoo UI/development work (use odoo-general skill).
---

# Odoo 19 External API Reference (SaaS / Odoo Online)

Verified live against an Odoo 19.0+e SaaS database (Custom plan with Studio). All
capabilities below are CONFIRMED unless marked otherwise.

---

## Connection Setup

### Config file pattern (`config.ini`)
```ini
[odoo]
url = https://instance.odoo.com
db = instance
username = user@email.com
api_key = <40-char hex token from user preferences>
```

- `db` = subdomain for Odoo Online (e.g. `herz` for `herz.odoo.com`)
- `username` = login email of the user who generated the API key
- API key is bound to the specific user - MUST match the login email

### JSON-2 API (USE THIS - XML-RPC is deprecated)

```python
import requests

config = configparser.ConfigParser()
config.read('config.ini')
URL = config['odoo']['url'].strip().rstrip('/')
DB = config['odoo']['db'].strip()
API_KEY = config['odoo']['api_key'].strip()

HEADERS = {
    'Authorization': f'bearer {API_KEY}',
    'Content-Type': 'application/json; charset=utf-8',
    'X-Odoo-Database': DB,   # optional if single-db instance
}

def call(model, method, **params):
    """Call any public Odoo model method via JSON-2."""
    r = requests.post(f'{URL}/json/2/{model}/{method}',
                      json=params, headers=HEADERS, timeout=30)
    if r.status_code != 200:
        raise Exception(f'{r.status_code}: {r.text[:500]}')
    return r.json()
```

### XML-RPC (DEPRECATED - removed on SaaS in 19.1, on-prem in 20)

```python
import xmlrpc.client

common = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/common')
uid = common.authenticate(DB, USERNAME, API_KEY, {})
models = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/object')

# All calls go through execute_kw:
result = models.execute_kw(DB, uid, API_KEY, 'model.name', 'method', [args], {kwargs})
```

Only use XML-RPC if something specific doesn't work on JSON-2. Migrate everything to JSON-2.

---

## JSON-2 ORM Methods - Exact Parameter Names

**CRITICAL**: JSON-2 requires exact named parameters. No positional args. Getting a name wrong = silent ignore or error.

### search (`@api.model`)
```python
call('res.partner', 'search',
     domain=[('is_company', '=', True)],
     offset=0, limit=10, order='name asc')
# Returns: list of IDs [1, 2, 3]
```

### search_count (`@api.model`)
```python
call('res.partner', 'search_count',
     domain=[('is_company', '=', True)])
# Returns: integer
```

### read (operates on recordset - needs `ids`)
```python
call('res.partner', 'read',
     ids=[1, 2, 3],
     fields=['name', 'email', 'phone'])
# Returns: list of dicts
```

### search_read (`@api.model` - PREFERRED over search + read)
```python
call('res.partner', 'search_read',
     domain=[('is_company', '=', True)],
     fields=['name', 'email'],
     offset=0, limit=5, order='name asc')
# Returns: list of dicts (single transaction, no race conditions)
```

### create (`@api.model`)
```python
call('res.partner', 'create',
     vals_list=[
         {'name': 'Acme Corp', 'is_company': True},
         {'name': 'Globex Inc', 'is_company': True},
     ])
# Returns: list of created IDs
# NOTE: vals_LIST (plural) - always a list of dicts, even for one record
```

### write (operates on recordset - needs `ids`)
```python
call('res.partner', 'write',
     ids=[1, 2],
     vals={'phone': '+421-555-0100'})
# Returns: True
# NOTE: vals (singular) - one dict applied to all ids
```

### unlink (operates on recordset - needs `ids`)
```python
call('res.partner', 'unlink', ids=[42, 43])
# Returns: True
```

### fields_get (`@api.model`)
```python
call('res.partner', 'fields_get',
     allfields=['name', 'email'],
     attributes=['string', 'type', 'required', 'readonly', 'relation'])
# Returns: dict of {field_name: {metadata}}
# Omit allfields to get ALL fields on the model
```

### web_read (Odoo 19 replacement for name_get)
```python
call('res.partner', 'web_read',
     ids=[1],
     specification={'name': {}, 'email': {}})
# Returns: list of dicts with display-ready values
```

---

## Context Passing

Context is a top-level key in the JSON body:

```python
call('res.partner', 'search_read',
     domain=[],
     fields=['name'],
     context={
         'lang': 'sk_SK',           # translations
         'tz': 'Europe/Bratislava',  # timezone
         'active_test': False,       # include archived records
         'bin_size': True,           # binary fields return size not content
         'allowed_company_ids': [1], # multi-company
     })
```

Common context keys:
- `lang` - language code for translated field values
- `tz` - timezone for datetime display
- `active_test` - `False` to include archived/inactive records (default `True`)
- `bin_size` - `True` to get file sizes instead of base64 for binary fields
- `allowed_company_ids` - list of company IDs for multi-company
- `active_model`, `active_id`, `active_ids` - needed when running server actions

---

## Domain Syntax

Standard Odoo domain format as JSON arrays:

```python
# Simple AND (default)
domain = [('is_company', '=', True), ('country_id.code', '=', 'SK')]

# OR (prefix notation)
domain = ['|', ('state', '=', 'draft'), ('state', '=', 'sent')]

# NOT
domain = ['!', ('active', '=', False)]

# Complex: (A AND (B OR C))
domain = [('type', '=', 'out_invoice'), '|', ('state', '=', 'draft'), ('state', '=', 'posted')]

# Operators: =, !=, >, >=, <, <=, like, ilike, not like, not ilike,
#            in, not in, child_of, parent_of, =like, =ilike
```

Dotted paths for relation traversal: `('partner_id.country_id.code', '=', 'SK')`

---

## One2many / Many2many Command Syntax

For relational fields (order_line, tag_ids, etc.), use ORM command tuples:

```python
# Create SO with order lines in ONE call (atomic)
call('sale.order', 'create', vals_list=[{
    'partner_id': 25,
    'order_line': [
        [0, 0, {'product_id': 15, 'product_uom_qty': 2}],   # create new line
        [0, 0, {'product_id': 6, 'product_uom_qty': 1}],    # create another
    ],
}])
```

Command reference:
| Command | Syntax | Effect |
|---------|--------|--------|
| Create  | `[0, 0, {values}]` | Create new related record |
| Update  | `[1, id, {values}]` | Update existing related record |
| Delete  | `[2, id, 0]` | Delete related record (from DB) |
| Unlink  | `[3, id, 0]` | Remove relation (keep record) |
| Link    | `[4, id, 0]` | Link existing record |
| Unlink all | `[5, 0, 0]` | Remove all relations |
| Replace | `[6, 0, [id_list]]` | Replace with exact set of IDs |

**DO NOT pass plain dicts for relational fields** - you'll get `unhashable type: 'dict'`.

---

## Calling Action Methods

Any public method (no underscore prefix) on any model is callable:

```python
# Confirm a sale order
call('sale.order', 'action_confirm', ids=[95])

# Cancel a sale order
call('sale.order', 'action_cancel', ids=[95])

# Validate a stock picking
call('stock.picking', 'button_validate', ids=[42])

# Confirm a purchase order
call('purchase.order', 'button_confirm', ids=[10])
```

Private methods (underscore-prefixed) return **403 Forbidden**:
```python
call('sale.order', '_action_cancel', ids=[95])  # 403!
```

---

## Meta-Model Operations (ALL CONFIRMED on SaaS)

### Create custom fields programmatically
```python
call('ir.model.fields', 'create', vals_list=[{
    'model_id': 90,                      # ir.model ID (NOT the model string)
    'name': 'x_custom_field',            # MUST start with x_
    'field_description': 'My Custom Field',
    'ttype': 'char',                     # char, integer, float, boolean, date, datetime,
                                         # text, html, selection, many2one, one2many, many2many
    'state': 'manual',                   # MUST be 'manual' for API-created fields
}])

# For selection fields:
call('ir.model.fields', 'create', vals_list=[{
    'model_id': 90,
    'name': 'x_priority',
    'field_description': 'Priority',
    'ttype': 'selection',
    'state': 'manual',
    'selection_ids': [
        [0, 0, {'value': 'low', 'name': 'Low', 'sequence': 1}],
        [0, 0, {'value': 'high', 'name': 'High', 'sequence': 2}],
    ],
}])

# For many2one:
call('ir.model.fields', 'create', vals_list=[{
    'model_id': 90,
    'name': 'x_related_project',
    'field_description': 'Related Project',
    'ttype': 'many2one',
    'relation': 'project.project',       # target model string
    'state': 'manual',
}])
```

### Create/modify inherited views
```python
# Find the base view to inherit from
base_views = call('ir.ui.view', 'search_read',
    domain=[('model', '=', 'res.partner'), ('type', '=', 'form'),
            ('inherit_id', '=', False)],
    fields=['id', 'name'], limit=1)

# Create inherited view (same as what Studio does)
call('ir.ui.view', 'create', vals_list=[{
    'name': 'partner_form_custom_api',
    'model': 'res.partner',
    'inherit_id': base_views[0]['id'],
    'arch': '''<data>
        <xpath expr="//field[@name='phone']" position="after">
            <field name="x_custom_field"/>
        </xpath>
    </data>''',
    'active': True,  # set False to create without activating
}])
```

### Create/modify security rules
```python
# Get model ID first
model = call('ir.model', 'search_read',
    domain=[('model', '=', 'project.task')],
    fields=['id'], limit=1)

call('ir.rule', 'create', vals_list=[{
    'name': 'Tasks: own company only',
    'model_id': model[0]['id'],
    'domain_force': "[('company_id', '=', user.company_id.id)]",
    'groups': [[6, 0, [group_id]]],  # apply to specific groups
    'perm_read': True,
    'perm_write': True,
    'perm_create': True,
    'perm_unlink': True,
    'active': True,
}])
```

### Read ACLs
```python
acls = call('ir.model.access', 'search_read',
    domain=[('model_id.model', '=', 'project.task')],
    fields=['name', 'group_id', 'perm_read', 'perm_write', 'perm_create', 'perm_unlink'])
```

---

## Server Actions - Create AND Execute via API

**CONFIRMED ON SAAS**: You can create server actions with `state='code'` and run them.
This was previously assumed to be blocked on SaaS. It is NOT blocked.

```python
# Get the model ID
model = call('ir.model', 'search_read',
    domain=[('model', '=', 'res.partner')],
    fields=['id'], limit=1)

# Create a server action with Python code
sa_ids = call('ir.actions.server', 'create', vals_list=[{
    'name': 'API: Update partner comments',
    'model_id': model[0]['id'],
    'state': 'code',
    'code': """
for rec in records:
    rec.write({'comment': 'Updated via API server action'})
""",
}])

# Run the server action against specific records
call('ir.actions.server', 'run',
     ids=sa_ids,
     context={
         'active_model': 'res.partner',
         'active_ids': [1, 2, 3],
         'active_id': 1,
     })

# Available variables in server action code:
# - env: the Odoo environment
# - model: the model object (e.g. env['res.partner'])
# - records: the recordset from active_ids
# - record: first record (or empty recordset)
# - time, datetime, dateutil, timezone: time utilities
# - float_compare, float_round, float_is_zero: float utilities
# - UserError, ValidationError: exceptions
# - Command: ORM command helper
# - log: logging function (writes to ir.logging)
# - action: dict to return as action result
```

### Non-code server action types (no safe_eval needed)
```python
# Object write
call('ir.actions.server', 'create', vals_list=[{
    'name': 'Set partner as company',
    'model_id': model[0]['id'],
    'state': 'object_write',
    'update_field_id': field_id,    # ir.model.fields ID
    'update_m2m_operation': 'set',  # for m2m fields
    'value': 'True',
}])

# Other state options: 'object_create', 'multi', 'mail', 'followers',
#                      'sms', 'next_activity'
```

---

## Automated Actions (base.automation)

```python
# Read existing automations
automations = call('base.automation', 'search_read',
    domain=[],
    fields=['name', 'model_id', 'trigger', 'action_server_ids'])

# Triggers: 'on_create', 'on_write', 'on_create_or_write',
#           'on_unlink', 'on_change', 'on_time', 'on_stage_set',
#           'on_tag_set', 'on_state_set', 'on_priority_set'
```

---

## File Upload / Download (ir.attachment)

```python
import base64

# Upload
content = base64.b64encode(open('file.pdf', 'rb').read()).decode()
att_ids = call('ir.attachment', 'create', vals_list=[{
    'name': 'document.pdf',
    'type': 'binary',
    'datas': content,
    'res_model': 'sale.order',   # attach to a record
    'res_id': 93,
}])

# Download
att_data = call('ir.attachment', 'read',
    ids=att_ids,
    fields=['name', 'datas', 'file_size', 'mimetype'])
file_bytes = base64.b64decode(att_data[0]['datas'])
with open('downloaded.pdf', 'wb') as f:
    f.write(file_bytes)

# List attachments for a record
attachments = call('ir.attachment', 'search_read',
    domain=[('res_model', '=', 'sale.order'), ('res_id', '=', 93)],
    fields=['name', 'file_size', 'mimetype', 'create_date'])
```

---

## Schema Introspection

### Full model field dump
```python
fields = call('res.partner', 'fields_get',
    attributes=['string', 'type', 'required', 'readonly',
                'relation', 'selection', 'help', 'store'])
for name, meta in fields.items():
    print(f"{name}: {meta['type']} - {meta['string']}")
```

### List all models
```python
models = call('ir.model', 'search_read',
    domain=[],
    fields=['model', 'name', 'state', 'transient'],
    order='model asc')
```

### List custom (Studio/x_) fields on a model
```python
custom = call('ir.model.fields', 'search_read',
    domain=[('model', '=', 'res.partner'), ('name', 'like', 'x_%')],
    fields=['name', 'field_description', 'ttype', 'state'])
```

### Get ir.config_parameter (system settings)
```python
params = call('ir.config_parameter', 'search_read',
    domain=[],
    fields=['key', 'value'])
```

---

## Email Templates

```python
# List templates for a model
templates = call('mail.template', 'search_read',
    domain=[('model', '=', 'sale.order')],
    fields=['name', 'subject', 'email_from', 'email_to'])

# Send an email using a template
call('mail.template', 'send_mail',
     ids=[template_id],
     res_id=sale_order_id,     # the record to render the template against
     force_send=True)
```

---

## Error Handling (JSON-2)

JSON-2 returns proper HTTP status codes:

| Status | Meaning | Example |
|--------|---------|---------|
| 200 | Success | Return value in body |
| 401 | Unauthorized | Invalid/missing API key |
| 403 | Forbidden | Private method or insufficient ACL |
| 404 | Not found | Model or method doesn't exist |
| 500 | Server error | Python exception during execution |

Error response body:
```json
{
  "name": "builtins.ValueError",
  "message": "Human-readable error description",
  "arguments": ["error args"],
  "context": {},
  "debug": "Full Python traceback..."
}
```

### Robust call wrapper
```python
def call(model, method, **params):
    r = requests.post(f'{URL}/json/2/{model}/{method}',
                      json=params, headers=HEADERS, timeout=30)
    if r.status_code == 200:
        return r.json()
    err = r.json() if r.headers.get('content-type','').startswith('application/json') else {}
    msg = err.get('message', r.text[:500])
    raise Exception(f'[{r.status_code}] {model}.{method}: {msg}')
```

---

## What DOES NOT Work on SaaS

| Blocked | Why | Workaround |
|---------|-----|------------|
| Custom Python modules | No filesystem / code deployment | Use API scripts + server actions with `state='code'` |
| Adding new Python methods to models | No code deployment | Call existing public methods or create server actions |
| Direct SQL (`env.cr.execute`) | No raw DB access | Use ORM methods through API |
| Private methods (`_render_qweb_pdf` etc.) | Underscore prefix = private | Session auth workaround for reports (needs local password) |
| PDF report download via API key | `/report/pdf/` endpoint requires session cookie, not bearer auth | Set a local password on the user, use session auth |
| Installing custom/3rd-party modules | SaaS restriction | Only official Odoo apps via UI |
| Parallel API calls | Rate limit ~1 req/sec | Batch within single calls (vals_list, multi-id write) |

### PDF Reports — Session Auth Workaround
```python
# Requires user to have a LOCAL PASSWORD set (not just SSO/OAuth)
# Session auth with an API key as password typically returns UID=None on SaaS —
# the account needs an actual local password.
session = requests.Session()
r = session.post(f'{URL}/web/session/authenticate', json={
    'jsonrpc': '2.0', 'method': 'call',
    'params': {'db': DB, 'login': USERNAME, 'password': LOCAL_PASSWORD}
})
uid = r.json().get('result', {}).get('uid')
if uid:
    pdf = session.get(f'{URL}/report/pdf/sale.report_saleorder/{so_id}')
    # pdf.content = raw PDF bytes
```

---

## Version Info

```python
# JSON-2 way (no auth needed)
r = requests.get(f'{URL}/web/version', headers=HEADERS)
# Returns: {"version_info": [19, 0, 0, "final", 0, "e"], "version": "19.0+e"}
```

---

## /doc Endpoint (Auto-Generated API Docs)

Available at `https://instance.odoo.com/doc` - requires login (session-based, not bearer).
- Browse all models, fields, and public methods
- Generates code snippets in cURL, Python, JavaScript, JSON
- Can test API calls directly in browser
- Requires "Technical Documentation Users" group

---

## Odoo 19 API Notes

- `name_get` does NOT exist in Odoo 19 — use `web_read` with `specification` instead.
- On a typical Enterprise SaaS install, expect ~300+ installed modules, ~850+ registered
  models, and 18k+ field definitions. Use `/doc` or `ir.model` / `ir.model.fields`
  introspection to confirm per-instance.

## Quick Capability Matrix (verified on Odoo 19.0 SaaS Enterprise)

| Operation | XML-RPC | JSON-2 | Status |
|-----------|---------|--------|--------|
| search/read/write/create/unlink | Yes | Yes | CONFIRMED |
| search_read | Yes | Yes | CONFIRMED |
| fields_get | Yes | Yes | CONFIRMED |
| web_read | Untested | Yes | CONFIRMED |
| Action methods (action_confirm etc.) | Untested | Yes | CONFIRMED |
| ir.model.fields create (custom fields) | Yes | Untested | CONFIRMED (XML-RPC) |
| ir.ui.view create (inherited views) | Yes | Untested | CONFIRMED (XML-RPC) |
| ir.rule create (security rules) | Yes | Untested | CONFIRMED (XML-RPC) |
| ir.actions.server create+run (code) | Untested | Yes | CONFIRMED |
| ir.attachment create/read (files) | Yes | Untested | CONFIRMED (XML-RPC) |
| base.automation read | Untested | Yes | CONFIRMED |
| mail.template read | Untested | Yes | CONFIRMED |
| Context (active_test, lang, etc.) | Yes | Yes | CONFIRMED |
| One2many commands [0,0,{}] | Untested | Yes | CONFIRMED |
| PDF reports via bearer auth | N/A | No | BLOCKED (needs session) |
| Private methods (_prefix) | Blocked | 403 | BY DESIGN |

## Rate Limits

~1 request/second, no parallel calls. Enforced by Odoo Online infrastructure.
For bulk operations, batch within a single call:
- `create` with `vals_list` of N records
- `write` with N `ids` and one `vals` dict
- `unlink` with N `ids`
