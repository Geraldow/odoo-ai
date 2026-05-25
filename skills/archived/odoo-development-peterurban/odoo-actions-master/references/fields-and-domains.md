# Odoo Fields, Domains & Conventions — Quick Reference

## Table of Contents

1. [Magic Fields](#magic-fields)
2. [Field Types](#field-types)
3. [Field Attributes](#field-attributes)
4. [x2many Command Syntax](#x2many-command-syntax)
5. [Domain Syntax](#domain-syntax)
6. [Naming Conventions](#naming-conventions)

---

## Magic Fields

Automatically on EVERY model (except `_log_access = False`):

| Field | Type | Description |
|---|---|---|
| id | Integer | PK, auto-increment |
| create_uid | M2O → res.users | Who created |
| create_date | Datetime | When created |
| write_uid | M2O → res.users | Who last modified |
| write_date | Datetime | When last modified |
| display_name | Char (computed) | From `_rec_name` (default: `name`) |

These fields CANNOT be set manually via write/create. The ORM manages them automatically.

---

## Field Types

### Text

```python
name = fields.Char(string='Name', required=True)           # max ~255 chars
description = fields.Text(string='Description')             # unlimited text
notes = fields.Html(string='Notes')                         # rich text / HTML
```

### Numeric

```python
quantity = fields.Integer(string='Quantity', default=1)
price = fields.Float(string='Price', digits=(10, 2))       # 10 total, 2 decimal
amount = fields.Monetary(string='Amount', currency_field='currency_id')
```

`Monetary` requires `currency_field` — the name of the M2O field to `res.currency` on the same model.

### Boolean

```python
active = fields.Boolean(string='Active', default=True)
```

### Date/Time

```python
date_order = fields.Date(string='Order Date', default=fields.Date.today)
created_at = fields.Datetime(string='Created', default=fields.Datetime.now)
```

### Selection

```python
state = fields.Selection([
    ('draft', 'Draft'),
    ('confirmed', 'Confirmed'),
    ('done', 'Done'),
    ('cancel', 'Cancelled'),
], string='Status', default='draft', required=True)
```

Stored in the DB is the VALUE (first element), the LABEL (second) is shown.

### Relational

```python
# Many2one — FK to another model, stores integer ID
partner_id = fields.Many2one('res.partner', string='Partner', ondelete='restrict')

# One2many — virtual reverse, no DB column
line_ids = fields.One2many('sale.order.line', 'order_id', string='Lines')

# Many2many — junction table
tag_ids = fields.Many2many(
    'product.tag',                # comodel
    'product_tag_rel',            # junction table (optional, auto-generated)
    'product_id',                 # column1 (optional)
    'tag_id',                     # column2 (optional)
    string='Tags'
)
```

**Junction table default naming**: alphabetical sort of both model table names + `_rel`

### Binary / Image

```python
file_data = fields.Binary(string='File', attachment=True)   # stored in ir.attachment
image = fields.Image(string='Image', max_width=1920, max_height=1920)
```

### Reference (polymorphic)

```python
document = fields.Reference([
    ('sale.order', 'Sales Order'),
    ('purchase.order', 'Purchase Order'),
], string='Document')
```

In the DB: varchar `'sale.order,42'`. No FK constraint — orphaned references are not cleaned up automatically.

---

## Field Attributes

### Common attributes

| Attribute | Type | Description |
|---|---|---|
| string | str | Displayed label |
| required | bool | Required field (default: False) |
| readonly | bool | Read-only (default: False) |
| store | bool | Stored in DB (default: True for non-computed) |
| compute | str | Name of the compute method |
| inverse | str | Name of the inverse method (for writable computed) |
| related | str | Path through relations: `'partner_id.country_id'` |
| default | value/callable | Default value or lambda |
| copy | bool | Copy on duplicate (default: True) |
| index | bool | DB index (default: False) |
| tracking | bool/int | Change tracking in chatter |
| groups | str | Visibility: `'base.group_system'` |
| help | str | Tooltip text |

### M2O-specific

| Attribute | Values | Description |
|---|---|---|
| ondelete | 'set null' | Sets NULL (default) |
| | 'restrict' | Prevents deleting the parent |
| | 'cascade' | Also deletes the child |

**GOTCHA**: `required=True` + `ondelete='set null'` = **Registry Load Failure**! Always use `restrict` or `cascade` with a required M2O.

### Computed fields

```python
total = fields.Float(compute='_compute_total', store=True)

@api.depends('line_ids.price_subtotal')
def _compute_total(self):
    for record in self:
        record.total = sum(record.line_ids.mapped('price_subtotal'))
```

- `store=True` → stored in DB, recomputed when dependencies change
- `store=False` (default for computed) → computed on-the-fly, not searchable
- `inverse` → allows writing to a computed field

### Related fields

```python
partner_country = fields.Char(related='partner_id.country_id.name', store=True)
```

- Shortcut for a simple compute through relations
- `store=True` → materialized in DB (fast search, but needs recompute)
- `store=False` → always fresh, but not searchable

---

## x2many Command Syntax

### Tuple format (legacy, still works)

```python
# (command, id, values)
(0, 0, {'name': 'New'})           # CREATE — new record with values
(1, id, {'name': 'Updated'})      # UPDATE — modifies an existing record
(2, id, 0)                         # DELETE — deletes a record from DB
(3, id, 0)                         # UNLINK — detaches from the relation (no delete)
(4, id, 0)                         # LINK — adds an existing record to the relation
(5, 0, 0)                          # CLEAR — detaches all (M2M: unlink, O2M: delete)
(6, 0, [id1, id2, id3])           # REPLACE — sets the exact set of IDs
```

### Command class (v15+, preferred)

```python
from odoo.fields import Command

Command.create({'name': 'New'})           # = (0, 0, vals)
Command.update(id, {'name': 'Updated'})   # = (1, id, vals)
Command.delete(id)                         # = (2, id, 0)
Command.unlink(id)                         # = (3, id, 0)
Command.link(id)                           # = (4, id, 0)
Command.clear()                            # = (5, 0, 0)
Command.set([id1, id2, id3])              # = (6, 0, ids)
```

### Usage

```python
# Create SO with lines
env['sale.order'].create({
    'partner_id': partner.id,
    'order_line': [
        Command.create({'product_id': 1, 'product_uom_qty': 5}),
        Command.create({'product_id': 2, 'product_uom_qty': 3}),
    ]
})

# Update — add a line, modify existing, delete another
order.write({
    'order_line': [
        Command.create({'product_id': 3, 'product_uom_qty': 1}),
        Command.update(line_id, {'product_uom_qty': 10}),
        Command.delete(old_line_id),
    ]
})

# M2M — groups on a user
user.write({
    'groups_id': [
        Command.link(group_id),              # add group
        # OR
        Command.set([g1, g2, g3]),           # replace all
    ]
})
```

### In safe_eval (server actions)

In the Odoo 17+ safe_eval context `Command` is available:

```python
# In automated action code:
record.write({'tag_ids': [Command.link(tag_id)]})
```

For older versions or when Command is not available, use the tuple syntax:

```python
record.write({'tag_ids': [(4, tag_id, 0)]})
```

---

## Domain Syntax

### Basic structure

```python
domain = [('field_name', 'operator', value)]
```

### Operators

| Operator | Description | Example |
|---|---|---|
| `=` | Equals | `('state', '=', 'draft')` |
| `!=` | Not equal | `('state', '!=', 'cancel')` |
| `>` | Greater than | `('amount', '>', 1000)` |
| `>=` | Greater than or equal | `('date', '>=', '2025-01-01')` |
| `<` | Less than | `('qty', '<', 0)` |
| `<=` | Less than or equal | `('date', '<=', '2025-12-31')` |
| `in` | In list | `('state', 'in', ['draft', 'sent'])` |
| `not in` | Not in list | `('state', 'not in', ['cancel', 'done'])` |
| `like` | Case-sensitive, auto-wildcards | `('name', 'like', 'order')` → %order% |
| `ilike` | Case-insensitive, auto-wildcards | `('name', 'ilike', 'order')` |
| `=like` | Case-sensitive, exact pattern | `('name', '=like', 'SO%')` |
| `=ilike` | Case-insensitive, exact pattern | `('email', '=ilike', '%@gmail.com')` |
| `child_of` | Hierarchically below | `('department_id', 'child_of', parent_id)` |
| `parent_of` | Hierarchically above | `('location_id', 'parent_of', child_id)` |
| `any` | At least one O2M match | `('line_ids', 'any', [('qty', '>', 0)])` |
| `not any` | No O2M match | `('line_ids', 'not any', [('qty', '>', 0)])` |

### Logical operators (Polish notation)

```python
# Default: AND (implicit between conditions)
[('state', '=', 'draft'), ('amount', '>', 100)]
# ≡ state=draft AND amount>100

# OR: prefix '|'
['|', ('state', '=', 'draft'), ('state', '=', 'sent')]
# ≡ state=draft OR state=sent

# NOT: prefix '!'
['!', ('active', '=', False)]
# ≡ NOT(active=False) → active is True

# Complex: (A AND B) OR C
['|', '&', ('state', '=', 'draft'), ('amount', '>', 100), ('priority', '=', 'high')]

# 3x OR: 2x '|' prefix
['|', '|', ('state', '=', 'a'), ('state', '=', 'b'), ('state', '=', 'c')]
# ≡ state=a OR state=b OR state=c
# Rule: N conditions with OR = N-1 '|' operators
```

### Gotchas

1. **Field-to-field compare IS NOT POSSIBLE:**
   ```python
   # WRONG — does not work:
   [('date_done', '<=', 'commitment_date')]
   
   # FIX: stored computed helper field or Python code
   ```

2. **`!=` excludes False/NULL:**
   ```python
   # ('field', '!=', 'x') DOES NOT INCLUDE records where field is False
   # FIX:
   ['|', ('field', '=', False), ('field', '!=', 'x')]
   ```

3. **O2M domains are limited:**
   ```python
   # Simple O2M domain works for ANY:
   [('line_ids.product_id', '=', product_id)]
   # → "at least one line has this product"
   
   # ALL lines matching a condition → not possible in a domain, use a computed field
   ```

4. **`any` / `not any` operators (v17+):**
   ```python
   # New in v17 — cleaner than path syntax:
   [('line_ids', 'any', [('state', '=', 'done')])]
   [('line_ids', 'not any', [('state', '=', 'cancel')])]
   ```

5. **Archived records:**
   ```python
   # active=False records are HIDDEN by default in search!
   # To also see archived:
   env['model'].with_context(active_test=False).search([...])
   ```

---

## Naming Conventions

### Standard Odoo conventions

| Pattern | Description | Examples |
|---|---|---|
| `*_id` | Many2one | partner_id, company_id, user_id |
| `*_ids` | Many2many / One2many | tag_ids, line_ids, order_ids |
| `state` | Selection — workflow state | draft/confirmed/done/cancel |
| `active` | Boolean — archiving | True = active |
| `sequence` | Integer — ordering | Drag-drop ordering |
| `company_id` | M2O → res.company | Multi-company |
| `currency_id` | M2O → res.currency | Currency |

### Field prefixes

| Prefix | Source | Example |
|---|---|---|
| (none) | Module code | `partner_id`, `state` |
| `x_` | Created via UI (Technical) | `x_custom_field` |
| `x_studio_` | Created via Studio | `x_studio_priority` |

### Gotcha: Studio field suffix

If you delete and recreate a Studio field → `x_studio_field_1` (not the original name).
ALWAYS verify the Technical Name before using it in a domain/code.

### Model naming

```
module.model_name      # Dotted notation (Python)
module_model_name      # Underscore notation (DB table)

sale.order       → sale_order (table)
sale.order.line  → sale_order_line (table)
res.partner      → res_partner (table)
```

### XML ID convention

```
module.category_model_name   # Typical format
base.group_user              # Group: base module, group_user
sale.action_quotations_with_onboarding  # Window action
```
