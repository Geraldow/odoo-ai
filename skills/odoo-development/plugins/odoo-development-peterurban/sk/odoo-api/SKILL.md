---
name: odoo-api
description: Použite túto skill vždy, keď pracujete s externým API Odoo - JSON-2 alebo XML-RPC. Spúšťače zahŕňajú akúkoľvek zmienku o 'Odoo API', 'JSON-2', 'XML-RPC', 'externom API', 'API key', 'bearer auth', 'api.anthropic', '/json/2/', 'execute_kw', 'search_read cez API', 'programový prístup k Odoo', alebo pri písaní Python skriptov, ktoré volajú Odoo vzdialene (nie server actions). Použite aj vtedy, keď sa používateľ pýta na vytváranie polí/pohľadov/pravidiel programovo cez API, upload/download súborov cez ir.attachment, alebo spúšťanie server actions z externých skriptov. NEPOUŽÍVAJTE pre server actions bežiace vo vnútri Odoo (použite odoo-server-actions skill) ani pre všeobecnú prácu s UI/vývojom Odoo (použite odoo-general skill).
---

# Referencia externého API Odoo 19 (SaaS / Odoo Online)

Overené naživo proti databáze Odoo 19.0+e SaaS (Custom plán so Studio). Všetky
nižšie uvedené možnosti sú POTVRDENÉ, pokiaľ nie je uvedené inak.

---

## Nastavenie pripojenia

### Vzor konfiguračného súboru (`config.ini`)
```ini
[odoo]
url = https://instance.odoo.com
db = instance
username = user@email.com
api_key = <40-char hex token from user preferences>
```

- `db` = subdoména pre Odoo Online (napr. `herz` pre `herz.odoo.com`)
- `username` = prihlasovací email používateľa, ktorý vygeneroval API key
- API key je viazaný na konkrétneho používateľa - MUSÍ zodpovedať prihlasovaciemu emailu

### JSON-2 API (POUŽITE TOTO - XML-RPC je zastaraný)

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

### XML-RPC (ZASTARANÝ - odstránený na SaaS v 19.1, on-prem v 20)

```python
import xmlrpc.client

common = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/common')
uid = common.authenticate(DB, USERNAME, API_KEY, {})
models = xmlrpc.client.ServerProxy(f'{URL}/xmlrpc/2/object')

# All calls go through execute_kw:
result = models.execute_kw(DB, uid, API_KEY, 'model.name', 'method', [args], {kwargs})
```

XML-RPC používajte iba ak niečo konkrétne nefunguje na JSON-2. Všetko migrujte na JSON-2.

---

## JSON-2 ORM metódy - presné názvy parametrov

**KRITICKÉ**: JSON-2 vyžaduje presné pomenované parametre. Žiadne pozičné argumenty. Nesprávny názov = tichá ignorácia alebo chyba.

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

### read (operuje na recordsete - vyžaduje `ids`)
```python
call('res.partner', 'read',
     ids=[1, 2, 3],
     fields=['name', 'email', 'phone'])
# Returns: list of dicts
```

### search_read (`@api.model` - PREFEROVANÉ pred search + read)
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

### write (operuje na recordsete - vyžaduje `ids`)
```python
call('res.partner', 'write',
     ids=[1, 2],
     vals={'phone': '+421-555-0100'})
# Returns: True
# NOTE: vals (singular) - one dict applied to all ids
```

### unlink (operuje na recordsete - vyžaduje `ids`)
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

### web_read (Odoo 19 náhrada za name_get)
```python
call('res.partner', 'web_read',
     ids=[1],
     specification={'name': {}, 'email': {}})
# Returns: list of dicts with display-ready values
```

---

## Odovzdávanie kontextu

Kontext je top-level kľúč v JSON body:

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

Bežné kontextové kľúče:
- `lang` - jazykový kód pre preložené hodnoty polí
- `tz` - časové pásmo pre zobrazenie datetime
- `active_test` - `False` pre zahrnutie archivovaných/neaktívnych záznamov (predvolené `True`)
- `bin_size` - `True` na získanie veľkostí súborov namiesto base64 pre binárne polia
- `allowed_company_ids` - zoznam ID spoločností pre multi-company
- `active_model`, `active_id`, `active_ids` - potrebné pri spúšťaní server actions

---

## Syntax domény

Štandardný formát domény Odoo ako JSON polia:

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

Bodkové cesty na prechádzanie relácií: `('partner_id.country_id.code', '=', 'SK')`

---

## Syntax príkazov One2many / Many2many

Pre relačné polia (order_line, tag_ids atď.) použite ORM command tuples:

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

Referencia príkazov:
| Príkaz | Syntax | Efekt |
|---------|--------|--------|
| Create  | `[0, 0, {values}]` | Vytvoriť nový súvisiaci záznam |
| Update  | `[1, id, {values}]` | Upraviť existujúci súvisiaci záznam |
| Delete  | `[2, id, 0]` | Vymazať súvisiaci záznam (z DB) |
| Unlink  | `[3, id, 0]` | Odstrániť reláciu (ponechať záznam) |
| Link    | `[4, id, 0]` | Napojiť existujúci záznam |
| Unlink all | `[5, 0, 0]` | Odstrániť všetky relácie |
| Replace | `[6, 0, [id_list]]` | Nahradiť presnou množinou ID |

**NEPOSIELAJTE obyčajné dicty pre relačné polia** - dostanete `unhashable type: 'dict'`.

---

## Volanie akčných metód

Akákoľvek verejná metóda (bez underscore prefixu) na akomkoľvek modeli je volateľná:

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

Súkromné metódy (s underscore prefixom) vracajú **403 Forbidden**:
```python
call('sale.order', '_action_cancel', ids=[95])  # 403!
```

---

## Meta-model operácie (VŠETKY POTVRDENÉ na SaaS)

### Vytvorenie vlastných polí programovo
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

### Vytvorenie/úprava zdedených pohľadov
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

### Vytvorenie/úprava bezpečnostných pravidiel
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

### Čítanie ACL
```python
acls = call('ir.model.access', 'search_read',
    domain=[('model_id.model', '=', 'project.task')],
    fields=['name', 'group_id', 'perm_read', 'perm_write', 'perm_create', 'perm_unlink'])
```

---

## Server Actions - vytvorenie AJ spustenie cez API

**POTVRDENÉ NA SAAS**: Môžete vytvárať server actions s `state='code'` a spúšťať ich.
Pôvodne sa predpokladalo, že je to na SaaS blokované. NIE JE to blokované.

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

### Non-code typy server actions (nie je potrebný safe_eval)
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

## Upload / download súborov (ir.attachment)

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

## Introspekcia schémy

### Úplný výpis polí modelu
```python
fields = call('res.partner', 'fields_get',
    attributes=['string', 'type', 'required', 'readonly',
                'relation', 'selection', 'help', 'store'])
for name, meta in fields.items():
    print(f"{name}: {meta['type']} - {meta['string']}")
```

### Zoznam všetkých modelov
```python
models = call('ir.model', 'search_read',
    domain=[],
    fields=['model', 'name', 'state', 'transient'],
    order='model asc')
```

### Zoznam vlastných (Studio/x_) polí na modeli
```python
custom = call('ir.model.fields', 'search_read',
    domain=[('model', '=', 'res.partner'), ('name', 'like', 'x_%')],
    fields=['name', 'field_description', 'ttype', 'state'])
```

### Získanie ir.config_parameter (systémové nastavenia)
```python
params = call('ir.config_parameter', 'search_read',
    domain=[],
    fields=['key', 'value'])
```

---

## Emailové šablóny

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

## Spracovanie chýb (JSON-2)

JSON-2 vracia správne HTTP stavové kódy:

| Status | Význam | Príklad |
|--------|---------|---------|
| 200 | Úspech | Návratová hodnota v body |
| 401 | Unauthorized | Nesprávny/chýbajúci API key |
| 403 | Forbidden | Súkromná metóda alebo nedostatočné ACL |
| 404 | Not found | Model alebo metóda neexistuje |
| 500 | Server error | Python výnimka počas vykonávania |

Telo chybovej odpovede:
```json
{
  "name": "builtins.ValueError",
  "message": "Human-readable error description",
  "arguments": ["error args"],
  "context": {},
  "debug": "Full Python traceback..."
}
```

### Robustný wrapper pre call
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

## Čo NEFUNGUJE na SaaS

| Blokované | Prečo | Riešenie |
|---------|-----|------------|
| Vlastné Python moduly | Žiadny filesystem / code deployment | Použite API skripty + server actions s `state='code'` |
| Pridávanie nových Python metód do modelov | Žiadny code deployment | Volajte existujúce verejné metódy alebo vytvorte server actions |
| Priame SQL (`env.cr.execute`) | Žiadny priamy prístup k DB | Použite ORM metódy cez API |
| Súkromné metódy (`_render_qweb_pdf` atď.) | Underscore prefix = private | Session auth workaround pre reporty (potrebuje lokálne heslo) |
| Download PDF reportu cez API key | `/report/pdf/` endpoint vyžaduje session cookie, nie bearer auth | Nastavte lokálne heslo pre používateľa, použite session auth |
| Inštalácia vlastných/3rd-party modulov | SaaS obmedzenie | Iba oficiálne Odoo apps cez UI |
| Paralelné API volania | Rate limit ~1 req/sec | Batchujte v rámci jedného volania (vals_list, multi-id write) |

### PDF Reporty — Session Auth Workaround
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

## Informácie o verzii

```python
# JSON-2 way (no auth needed)
r = requests.get(f'{URL}/web/version', headers=HEADERS)
# Returns: {"version_info": [19, 0, 0, "final", 0, "e"], "version": "19.0+e"}
```

---

## /doc Endpoint (automaticky generovaná API dokumentácia)

Dostupná na `https://instance.odoo.com/doc` - vyžaduje prihlásenie (session-based, nie bearer).
- Prehliadajte všetky modely, polia a verejné metódy
- Generuje ukážky kódu v cURL, Python, JavaScript, JSON
- Môžete testovať API volania priamo v prehliadači
- Vyžaduje skupinu "Technical Documentation Users"

---

## Poznámky k API v Odoo 19

- `name_get` v Odoo 19 NEEXISTUJE — použite `web_read` so `specification`.
- Pri typickej inštalácii Enterprise SaaS očakávajte ~300+ nainštalovaných modulov, ~850+ registrovaných
  modelov a 18k+ definícií polí. Použite `/doc` alebo introspekciu `ir.model` / `ir.model.fields`
  na overenie pre konkrétnu inštanciu.

## Rýchla matica schopností (overené na Odoo 19.0 SaaS Enterprise)

| Operácia | XML-RPC | JSON-2 | Stav |
|-----------|---------|--------|--------|
| search/read/write/create/unlink | Áno | Áno | POTVRDENÉ |
| search_read | Áno | Áno | POTVRDENÉ |
| fields_get | Áno | Áno | POTVRDENÉ |
| web_read | Netestované | Áno | POTVRDENÉ |
| Action methods (action_confirm atď.) | Netestované | Áno | POTVRDENÉ |
| ir.model.fields create (vlastné polia) | Áno | Netestované | POTVRDENÉ (XML-RPC) |
| ir.ui.view create (zdedené pohľady) | Áno | Netestované | POTVRDENÉ (XML-RPC) |
| ir.rule create (bezpečnostné pravidlá) | Áno | Netestované | POTVRDENÉ (XML-RPC) |
| ir.actions.server create+run (code) | Netestované | Áno | POTVRDENÉ |
| ir.attachment create/read (súbory) | Áno | Netestované | POTVRDENÉ (XML-RPC) |
| base.automation read | Netestované | Áno | POTVRDENÉ |
| mail.template read | Netestované | Áno | POTVRDENÉ |
| Kontext (active_test, lang, atď.) | Áno | Áno | POTVRDENÉ |
| One2many príkazy [0,0,{}] | Netestované | Áno | POTVRDENÉ |
| PDF reporty cez bearer auth | N/A | Nie | BLOKOVANÉ (potrebuje session) |
| Súkromné metódy (_prefix) | Blokované | 403 | BY DESIGN |

## Rate Limits

~1 požiadavka/sekunda, žiadne paralelné volania. Vynútené infraštruktúrou Odoo Online.
Pre hromadné operácie batchujte v rámci jedného volania:
- `create` s `vals_list` N záznamov
- `write` s N `ids` a jedným `vals` dictom
- `unlink` s N `ids`
