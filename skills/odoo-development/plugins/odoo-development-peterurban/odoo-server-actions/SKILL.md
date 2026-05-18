---
name: odoo-server-actions
description: ALWAYS read this skill BEFORE writing any Odoo server action code. Covers safe_eval limitations, forbidden builtins, dunder restrictions, UserError rollback gotchas, and verified patterns for Odoo 18/19 SaaS. Trigger whenever the user asks to write, edit, debug, or review server actions, automated actions, or any Python code that runs in Odoo's safe_eval context.
---

# Odoo SaaS Safe_eval Reference (Verified on 19.0 SaaS, Feb 2026)

Based on real testing on Odoo SaaS 19.0 (February 2026). Earlier claims from January 2026 had errors — corrected below.

## 🔑 CRITICAL: Write Model-Agnostic Server Actions

**Always write SAs so they can run from ANY model** — the user has one reusable test SA and shouldn't have to move it between models. This means:

- **NEVER use `record`, `records`, or `model`** for the target data. These are bound to whichever model the SA is attached to, which may not be the model you care about.
- **ALWAYS use `env['target.model']`** to access the data you need. Use `.search()`, `.browse()`, or `.sudo().search()` explicitly.
- The SA's assigned model is irrelevant — treat it as a generic code runner.

```python
# BAD — breaks if SA is not on sale.order:
for rec in records:
    output.append(rec.name)

# GOOD — works from any model:
orders = env['sale.order'].sudo().search([], limit=5)
for rec in orders:
    output.append(rec.name)
```

The only exception is automation rules (base.automation) where `records` IS the trigger record and the model binding matters. For manual diagnostic/utility SAs, always go model-agnostic.

## ✅ AVAILABLE in safe_eval

### Globals
```python
datetime          # datetime module
time              # time module  
UserError         # for raising user-friendly errors (but causes ROLLBACK!)
env               # Odoo environment
record / records  # current record(s) in Server Action context
model             # current model
```

### Built-in Functions
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

### String/List Operations
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

## ❌ NOT AVAILABLE in safe_eval

### Forbidden Built-ins
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

### ⚠️ DUNDER (Double Underscore) Restrictions - CRITICAL!

**safe_eval blocks ALL access to double-underscore names, including in STRING VALUES!**

This is validated at CODE SAVE TIME, not runtime - you can't even save the server action.

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

### Forbidden Exceptions (cannot raise directly)
```python
ValueError         # NameError - not defined
TypeError          # NameError - not defined
KeyError           # NameError - not defined
AttributeError     # NameError - not defined
Exception          # NameError - not defined
Warning            # NameError - not defined
# ONLY UserError is available!
```

### Forbidden Modules
```python
import os          # FORBIDDEN
import sys         # FORBIDDEN
import subprocess  # FORBIDDEN
import requests    # FORBIDDEN
# Basically ALL imports are forbidden
```

## ⚠️ GOTCHAS & WORKAROUNDS

### 1. raise UserError causes ROLLBACK! — CRITICAL decision point

**This is the #1 footgun in server actions.** You MUST decide upfront whether your SA
writes data or is read-only, and pick the output method accordingly.

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

### 2. res.users groups field — VERIFIED on 19.0 SaaS

```python
# The field name is groups_id — this has NOT changed across versions.
# Tested and confirmed on Odoo 19.0 SaaS (February 2026).

user.groups_id          # CORRECT - Many2many to res.groups, works on ALL versions
user.groups_id.ids      # list of group IDs

# WRONG - these DO NOT EXIST on res.users:
user.group_ids          # AttributeError!
user.all_group_ids      # AttributeError!
```

### 3. Group membership check
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

### 4. Checking field existence
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

### 5. Diagnostics output patterns
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

### 6. String formatting (no f-strings in older Odoo)
```python
# SAFE - works everywhere:
"Value: %s" % value
"Name: %s, ID: %s" % (name, id)

# ALSO SAFE:
"Value: {}".format(value)

# f-strings - test first, may not work in all contexts
```

### 7. Iterating with modifications
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

### 8. env.ref safety
```python
# WRONG - crashes if not found:
group = env.ref('module.xml_id')

# CORRECT:
group = env.ref('module.xml_id', raise_if_not_found=False)
if group:
    # use group
```

### 9. Switching user context
```python
# CORRECT way to test as another user:
other_user = env['res.users'].sudo().browse(user_id)
other_env = env(user=other_user.id)
# Now use other_env for searches/reads

# WRONG (may not work):
other_user.with_user(other_user).env
```

### 10. Long output - use batches
```python
# If output too long for UserError, split into batches:
users = env['res.users'].sudo().search([...], limit=10, offset=0)   # Batch 1
users = env['res.users'].sudo().search([...], limit=10, offset=10)  # Batch 2
```

### 11. Getting field metadata without dunders or type()
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

### 12. Creating test records - avoid dunder names
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

## Common Patterns

### Diagnostic Server Action Template
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

### Field Metadata Inspection Template
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

### Write + Notify Template
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

### Group Manipulation Template
```python
# Add group to user (field is groups_id, NOT group_ids!)
user.sudo().write({'groups_id': [(4, group_id, 0)]})  # 4 = add

# Remove group from user  
user.sudo().write({'groups_id': [(3, group_id, 0)]})  # 3 = remove

# Replace all groups
user.sudo().write({'groups_id': [(6, 0, [list_of_ids])]})  # 6 = replace
```

### Record Rule Check Template
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

### Access Diagnostic Template (ACLs + Record Rules + Live Test)
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

### SQL Query Template (for diagnostics)
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

### Safe Rollback Test Pattern
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

## Quick Reference - What's Forbidden

| Pattern | Error | Workaround |
|---------|-------|------------|
| `type(x)` | NameError (SaaS) | check field attrs directly |
| `hasattr(x, 'y')` | forbidden opcode | `'y' in x._fields` |
| `getattr(x, 'y')` | forbidden opcode | `x.y` or try/except |
| `type(x).__name__` | forbidden name | N/A (type itself unavailable) |
| `x.__dict__` | forbidden name | direct attribute access |
| `'__test__'` | forbidden name | `'TEMP_test'` |
| `import x` | forbidden | use preloaded globals |
| `raise ValueError` | NameError | `raise UserError` |
| `dir(x)` | NameError | manual attribute checks |
| `user.group_ids` | AttributeError | `user.groups_id` |

## Quick Reference - Output Method Decision

| SA purpose | Output method | Rollback? |
|------------|--------------|-----------|
| Read-only diagnostic | `raise UserError(...)` | Yes (doesn't matter) |
| Write data + confirm | `action = {display_notification}` | No (writes persist) |
| Test write without saving | `write() + raise UserError(...)` | Yes (intentional) |
