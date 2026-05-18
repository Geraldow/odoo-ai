---
name: odoo-server-actions
description: VŽDY si prečítajte túto skill PRED napísaním akéhokoľvek Odoo server action kódu. Pokrýva obmedzenia safe_eval, zakázané builtins, dunder obmedzenia, UserError rollback úskalia a overené vzory pre Odoo 18/19 SaaS. Spúšťajte vždy, keď používateľ žiada napísať, upraviť, debugovať alebo zrevidovať server actions, automated actions alebo akýkoľvek Python kód, ktorý beží v safe_eval kontexte Odoo.
---

# Odoo SaaS Safe_eval referencia (overené na 19.0 SaaS, február 2026)

Založené na reálnom testovaní na Odoo SaaS 19.0 (február 2026). Skoršie tvrdenia z januára 2026 mali chyby — opravené nižšie.

## 🔑 KRITICKÉ: Píšte model-agnostic server actions

**Vždy píšte SA tak, aby mohli bežať z LUBOVOĽNÉHO modelu** — používateľ má jednu reusable test SA a nemal by ju musieť presúvať medzi modelmi. To znamená:

- **NIKDY nepoužívajte `record`, `records` ani `model`** pre cieľové dáta. Tieto sú bindované na model, na ktorý je SA pripojená, čo nemusí byť model, ktorý vás zaujíma.
- **VŽDY používajte `env['target.model']`** na prístup k dátam, ktoré potrebujete. Použite `.search()`, `.browse()` alebo `.sudo().search()` explicitne.
- Priradený model SA je irelevantný — správajte sa k nemu ako ku generic code runneru.

```python
# BAD — breaks if SA is not on sale.order:
for rec in records:
    output.append(rec.name)

# GOOD — works from any model:
orders = env['sale.order'].sudo().search([], limit=5)
for rec in orders:
    output.append(rec.name)
```

Jedinou výnimkou sú automation rules (base.automation), kde `records` JE trigger record a model binding je dôležitý. Pre manuálne diagnostic/utility SAs vždy píšte model-agnostic.

## ✅ DOSTUPNÉ v safe_eval

### Globály
```python
datetime          # datetime module
time              # time module  
UserError         # for raising user-friendly errors (but causes ROLLBACK!)
env               # Odoo environment
record / records  # current record(s) in Server Action context
model             # current model
```

### Built-in funkcie
```python
len()
str()
int()
float()
list()
dict()
set()
tuple()
sorted()
any()
all()
sum()
min()
max()
abs()
round()
range()
enumerate()
zip()
filter()
map()
repr()
bool()
isinstance()
```

### String/List operácie
```python
'string'.lower()
'string'.upper()
'string'.split()
'string'.join()
'string'.replace()
'string'.format()
'%s' % value       # string formatting
[].append()
[].extend()
{}.get()
{}.items()
{}.keys()
{}.values()
```

## ❌ NEDOSTUPNÉ v safe_eval

### Zakázané built-ins
```python
import             # FORBIDDEN - no imports allowed
type()             # NOT available on SaaS 19.0! NameError: name 'type' is not defined
dir()              # NameError: name 'dir' is not defined
eval()             # FORBIDDEN
exec()             # FORBIDDEN
compile()          # FORBIDDEN
open()             # FORBIDDEN
file()             # FORBIDDEN
input()            # FORBIDDEN
__import__()       # FORBIDDEN
globals()          # FORBIDDEN
locals()           # FORBIDDEN
vars()             # FORBIDDEN
hasattr()          # FORBIDDEN - "forbidden opcode"
getattr()          # FORBIDDEN - "forbidden opcode"
setattr()          # FORBIDDEN
delattr()          # FORBIDDEN
```

### ⚠️ DUNDER (Double Underscore) obmedzenia - KRITICKÉ!

**safe_eval blokuje VŠETKY prístupy k menám s dvojitým underscore, VRÁTANE v STRING HODNOTÁCH!**

Toto je validované v čase SAVE KÓDU, nie runtime - server action ani neuložíte.

```python
# FORBIDDEN - accessing __name__:
type(obj).__name__           # type() itself is NOT available on SaaS
field.__class__.__name__     # FORBIDDEN

# FORBIDDEN - accessing __dict__:
obj.__dict__                 # NameError: Access to forbidden name '__dict__'
field.__dict__.get('attr')   # FORBIDDEN

# FORBIDDEN - dunder in STRING LITERALS!
name = '__TEST__'            # FORBIDDEN at save time!
name = '__TEMP_RECORD__'     # FORBIDDEN!
msg = "Status: __PENDING__"  # FORBIDDEN!
env['model'].create({'name': '__anything__'})  # FORBIDDEN!

# WORKAROUNDS:

# Instead of type(obj), inspect field attributes directly:
try:
    val = field.related      # Direct attribute access works
except:
    val = None

try:
    val = field.compute
except:
    val = None

# For field type, check comodel_name or use str() on the field object:
field = env['model']._fields['field_name']
field_str = str(field)       # gives something like "model.field_name"
# Or check comodel_name for relational fields:
try:
    comodel = field.comodel_name  # e.g. 'res.partner' for Many2one
except:
    comodel = None

# Instead of dunder strings, use safe naming:
name = 'TEMP_TEST_RECORD'    # OK
name = 'TEST_PRIORITY'       # OK  
name = '_test_record'        # OK (single underscore is fine)
name = 'temp__test'          # OK (double underscore in middle, not prefix)
```

### Zakázané výnimky (nemožno raisovať priamo)
```python
ValueError         # NameError - not defined
TypeError          # NameError - not defined
KeyError           # NameError - not defined
AttributeError     # NameError - not defined
Exception          # NameError - not defined
Warning            # NameError - not defined
# ONLY UserError is available!
```

### Zakázané moduly
```python
import os          # FORBIDDEN
import sys         # FORBIDDEN
import subprocess  # FORBIDDEN
import requests    # FORBIDDEN
# Basically ALL imports are forbidden
```

## ⚠️ ÚSKALIA A WORKAROUNDS

### 1. raise UserError spôsobuje ROLLBACK! — KRITICKÝ bod rozhodnutia

**Toto je footgun č.1 v server actions.** MUSÍTE dopredu rozhodnúť, či vaša SA
zapisuje dáta alebo je read-only, a podľa toho zvoliť output metódu.

```python
# ============================================================
# RULE: If your SA WRITES data → use display_notification
#       If your SA only READS → raise UserError is fine
# ============================================================

# BAD - changes will be lost:
record.write({'field': 'value'})
raise UserError('Done!')  # ROLLBACK - write is undone!

# GOOD - use display_notification when you need writes to persist:
record.write({'field': 'value'})
action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {
        'title': 'Done',
        'message': 'Changes saved',
        'type': 'success',
        'sticky': True,
    }
}
# Note: action variable is returned implicitly

# GOOD - use UserError for READ-ONLY diagnostics (rollback doesn't matter):
output = []
output.append("Record: %s" % record.name)
output.append("Field: %s" % record.some_field)
raise UserError('\n'.join(output))  # Perfect for diagnostics

# GOOD - INTENTIONAL rollback: use UserError to test writes without persisting:
# (see Safe Rollback Test Pattern below)
```

### 2. res.users groups field — OVERENÉ na 19.0 SaaS

```python
# The field name is groups_id — this has NOT changed across versions.
# Tested and confirmed on Odoo 19.0 SaaS (February 2026).

user.groups_id          # CORRECT - Many2many to res.groups, works on ALL versions
user.groups_id.ids      # list of group IDs

# WRONG - these DO NOT EXIST on res.users:
user.group_ids          # AttributeError!
user.all_group_ids      # AttributeError!
```

### 3. Kontrola členstva v skupine
```python
# WRONG - groups object has no 'users' attribute in safe_eval:
group.users

# WRONG - trans_implied_ids doesn't exist:
group.trans_implied_ids

# CORRECT - check via user's groups_id:
group_id in user.groups_id.ids

# CORRECT - use has_group for xml_id based checks:
user.has_group('base.group_user')
```

### 4. Kontrola existencie poľa
```python
# WRONG - hasattr forbidden:
if hasattr(record, 'field_name'):

# CORRECT - check _fields dict:
if 'field_name' in env['model.name']._fields:
    # field exists on model

# CORRECT - check on record's model:
if 'field_name' in record._fields:
    value = record.field_name

# CORRECT - try/except for safety:
try:
    value = record.field_name
except:
    value = None
```

### 5. Vzory výstupu pre diagnostiku
```python
# For READ-ONLY diagnostics (changes don't matter):
output = []
output.append("Line 1")
output.append("Line 2")
raise UserError('\n'.join(output))

# For WRITE operations (need to persist):
# ... do your writes ...
action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {
        'title': 'Title',
        'message': 'Message here',
        'type': 'success',  # or 'warning', 'info', 'danger'
        'sticky': True,     # stays until dismissed
    }
}
```

### 6. String formatting (žiadne f-stringy v starších Odoo)
```python
# SAFE - works everywhere:
"Value: %s" % value
"Name: %s, ID: %s" % (name, id)

# ALSO SAFE:
"Value: {}".format(value)

# f-strings - test first, may not work in all contexts
```

### 7. Iterovanie s modifikáciami
```python
# WRONG - modifying during iteration:
for record in records:
    records |= other_record  # Don't modify the iterable!

# CORRECT:
to_add = env['model'].browse()
for record in records:
    to_add |= other_record
records |= to_add
```

### 8. env.ref bezpečnosť
```python
# WRONG - crashes if not found:
group = env.ref('module.xml_id')

# CORRECT:
group = env.ref('module.xml_id', raise_if_not_found=False)
if group:
    # use group
```

### 9. Prepínanie user kontextu
```python
# CORRECT way to test as another user:
other_user = env['res.users'].sudo().browse(user_id)
other_env = env(user=other_user.id)
# Now use other_env for searches/reads

# WRONG (may not work):
other_user.with_user(other_user).env
```

### 10. Dlhý output - použite batche
```python
# If output too long for UserError, split into batches:
users = env['res.users'].sudo().search([...], limit=10, offset=0)   # Batch 1
users = env['res.users'].sudo().search([...], limit=10, offset=10)  # Batch 2
```

### 11. Získavanie field metadata bez dunderov alebo type()
```python
# WRONG - type() not available on SaaS:
field_type = type(field).__name__    # FAILS: type not defined
field_attrs = field.__dict__         # FAILS: forbidden dunder

# CORRECT - direct attribute access:
output = []
field = env['project.task']._fields['worksheet_template_id']

# These work:
try:
    output.append("related: %s" % str(field.related))
except:
    output.append("related: N/A")

try:
    output.append("compute: %s" % str(field.compute))
except:
    output.append("compute: N/A")

try:
    output.append("store: %s" % str(field.store))
except:
    output.append("store: N/A")

try:
    output.append("comodel_name: %s" % str(field.comodel_name))
except:
    output.append("comodel_name: N/A")

# For discovering field names on a model:
for fname in env['model.name']._fields:
    if 'search_term' in fname.lower():
        field = env['model.name']._fields[fname]
        try:
            comodel = field.comodel_name
        except:
            comodel = 'N/A'
        try:
            store = field.store
        except:
            store = 'N/A'
        output.append("FIELD: %s | comodel: %s | store: %s" % (fname, comodel, store))
```

### 12. Vytváranie test záznamov - vyhnite sa dunder menám
```python
# WRONG - forbidden string literal:
test_record = env['worksheet.template'].sudo().create({
    'name': '__TEST_TEMPLATE__',
})

# CORRECT:
test_record = env['worksheet.template'].sudo().create({
    'name': 'TEMP_TEST_TEMPLATE',
})

# Also watch out in error messages:
# WRONG:
raise UserError("Status: __PENDING__")

# CORRECT:
raise UserError("Status: PENDING")
```

## Bežné vzory

### Šablóna pre diagnostickú Server Action
```python
# Safe diagnostic template - read only, MODEL-AGNOSTIC (run from any SA)
output = []

# Access any model directly via env, never via record/records
user = env['res.users'].sudo().browse(USER_ID)
output.append("User: %s" % user.name)
output.append("Groups: %s" % len(user.groups_id))

# Test access as that user
test_env = env(user=user.id)
try:
    count = test_env['model.name'].search_count([])
    output.append("Can see: %s records" % count)
except Exception as e:
    output.append("Access ERROR: %s" % str(e)[:100])

raise UserError('\n'.join(output))
```

### Šablóna pre inšpekciu metadát poľa
```python
# Safe way to inspect field properties
output = []
model_name = 'project.task'
field_name = 'worksheet_template_id'

output.append("=== FIELD ANALYSIS: %s.%s ===" % (model_name, field_name))

model = env[model_name]
if field_name in model._fields:
    field = model._fields[field_name]
    output.append("Field exists: YES")
    
    # Safe attribute access pattern
    for attr in ['related', 'compute', 'store', 'comodel_name', 'string', 'required']:
        try:
            val = None
            if attr == 'related':
                val = field.related
            elif attr == 'compute':
                val = field.compute
            elif attr == 'store':
                val = field.store
            elif attr == 'comodel_name':
                val = field.comodel_name
            elif attr == 'string':
                val = field.string
            elif attr == 'required':
                val = field.required
            output.append("  %s: %s" % (attr, val))
        except:
            output.append("  %s: N/A" % attr)
else:
    output.append("Field exists: NO")

raise UserError('\n'.join(output))
```

### Šablóna Write + Notify
```python
# Safe write with notification (changes PERSIST - no rollback)
target = env['model'].sudo().browse(RECORD_ID)
target.write({'field': 'value'})

action = {
    'type': 'ir.actions.client',
    'tag': 'display_notification',
    'params': {
        'title': 'Success',
        'message': 'Record updated',
        'type': 'success',
        'sticky': False,
    }
}
```

### Šablóna pre manipuláciu so skupinami
```python
# Add group to user (field is groups_id, NOT group_ids!)
user.sudo().write({'groups_id': [(4, group_id, 0)]})  # 4 = add

# Remove group from user  
user.sudo().write({'groups_id': [(3, group_id, 0)]})  # 3 = remove

# Replace all groups
user.sudo().write({'groups_id': [(6, 0, [list_of_ids])]})  # 6 = replace
```

### Šablóna pre kontrolu Record Rule
```python
model_name = 'hr.employee'
model_obj = env['ir.model'].sudo().search([('model', '=', model_name)], limit=1)
rules = env['ir.rule'].sudo().search([('model_id', '=', model_obj.id)])

output = []
for rule in rules:
    groups = [(g.id, g.name) for g in rule.groups] if rule.groups else 'GLOBAL'
    output.append("[%s] %s | groups: %s | domain: %s" % (
        rule.id, rule.name, groups, rule.domain_force
    ))
raise UserError('\n'.join(output))
```

### Šablóna pre diagnostiku prístupu (ACLs + Record Rules + Live Test)
```python
# Full access diagnostic for a specific user on a specific model
output = []
uid = 13  # <-- change to target user ID
model_name = 'project.task'  # <-- change to target model

user = env['res.users'].sudo().browse(uid)
output.append("=== USER: %s (id=%s) ===" % (user.name, user.id))
output.append("Active: %s | Groups: %s" % (user.active, len(user.groups_id)))

model_obj = env['ir.model'].sudo().search([('model', '=', model_name)], limit=1)
user_group_ids = set(user.groups_id.ids)

# ACLs
output.append("")
output.append("=== ACLs ===")
acls = env['ir.model.access'].sudo().search([('model_id', '=', model_obj.id)])
can_read = False
for acl in acls:
    grp = acl.group_id
    applies = not grp or grp.id in user_group_ids
    if applies and acl.perm_read:
        can_read = True
    marker = ">>>" if applies else "   "
    output.append("%s [%s] %s | grp: %s | R=%s W=%s C=%s U=%s" % (
        marker, acl.id, acl.name,
        grp.full_name if grp else 'GLOBAL',
        acl.perm_read, acl.perm_write, acl.perm_create, acl.perm_unlink
    ))
output.append("CAN READ: %s" % can_read)

# Record Rules
output.append("")
output.append("=== RECORD RULES ===")
rules = env['ir.rule'].sudo().search([('model_id', '=', model_obj.id)])
for rule in rules:
    groups = [(g.id, g.full_name) for g in rule.groups] if rule.groups else 'GLOBAL'
    applies = "GLOBAL" if not rule.groups else any(g.id in user_group_ids for g in rule.groups)
    output.append("[%s] %s | groups: %s | applies: %s | R=%s | domain: %s" % (
        rule.id, rule.name, groups, applies, rule.perm_read, rule.domain_force
    ))

# Live test
output.append("")
output.append("=== LIVE TEST ===")
test_env = env(user=uid)
try:
    count = test_env[model_name].search_count([])
    output.append("search_count: %s" % count)
except Exception as e:
    output.append("FAILED: %s" % str(e)[:300])

raise UserError('\n'.join(output))
```

### Šablóna pre SQL query (pre diagnostiku)
```python
# Direct SQL for reading constraints, schema info etc.
output = []

env.cr.execute("""
    SELECT conname, pg_get_constraintdef(oid) 
    FROM pg_constraint 
    WHERE conrelid = 'project_project'::regclass 
    AND contype = 'c'
""")
constraints = env.cr.fetchall()

for name, definition in constraints:
    output.append("[%s]" % name)
    output.append("  %s" % definition)

raise UserError('\n'.join(output))
```

### Vzor Safe Rollback Test
```python
# Use UserError rollback to test writes without persisting
output = []

# Make test changes
test_value = 'TEMP_TEST_VALUE'
record.sudo().write({'name': test_value})
output.append("Wrote: %s" % test_value)

# Verify write worked
output.append("Read back: %s" % record.name)

# This raises AND rolls back the write
raise UserError('\n'.join(output))
# After this, record.name is back to original value
```

## Rýchla referencia - Čo je zakázané

| Vzor | Chyba | Riešenie |
|---------|-------|------------|
| `type(x)` | NameError (SaaS) | priamo skontrolujte field atribúty |
| `hasattr(x, 'y')` | forbidden opcode | `'y' in x._fields` |
| `getattr(x, 'y')` | forbidden opcode | `x.y` alebo try/except |
| `type(x).__name__` | forbidden name | N/A (type samotný nedostupný) |
| `x.__dict__` | forbidden name | priamy attribute access |
| `'__test__'` | forbidden name | `'TEMP_test'` |
| `import x` | forbidden | použite prednačítané globály |
| `raise ValueError` | NameError | `raise UserError` |
| `dir(x)` | NameError | manuálne kontroly atribútov |
| `user.group_ids` | AttributeError | `user.groups_id` |

## Rýchla referencia - Rozhodnutie o output metóde

| Účel SA | Output metóda | Rollback? |
|------------|--------------|-----------|
| Read-only diagnostika | `raise UserError(...)` | Áno (nezáleží) |
| Write dáta + potvrdenie | `action = {display_notification}` | Nie (zápisy pretrvávajú) |
| Test write bez uloženia | `write() + raise UserError(...)` | Áno (zámerné) |
