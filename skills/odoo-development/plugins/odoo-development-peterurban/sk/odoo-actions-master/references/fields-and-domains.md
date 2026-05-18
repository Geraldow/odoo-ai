# Odoo polia, domény a konvencie — Quick Reference

## Obsah

1. [Magic fields](#magic-fields)
2. [Typy polí](#typy-poli)
3. [Atribúty polí](#atributy-poli)
4. [Syntax x2many commandov](#syntax-x2many-commandov)
5. [Domain syntax](#domain-syntax)
6. [Naming konvencie](#naming-konvencie)

---

## Magic fields

Automaticky na KAŽDOM modeli (okrem `_log_access = False`):

| Pole | Typ | Popis |
|---|---|---|
| id | Integer | PK, auto-increment |
| create_uid | M2O → res.users | Kto vytvoril |
| create_date | Datetime | Kedy vytvorený |
| write_uid | M2O → res.users | Kto naposledy zmenil |
| write_date | Datetime | Kedy naposledy zmenený |
| display_name | Char (computed) | Z `_rec_name` (default: `name`) |

Tieto polia sa NEDAJÚ nastaviť manuálne cez write/create. ORM ich spravuje automaticky.

---

## Typy polí

### Text

```python
name = fields.Char(string='Name', required=True)           # max ~255 znakov
description = fields.Text(string='Description')             # neobmedzený text
notes = fields.Html(string='Notes')                         # rich text / HTML
```

### Číselné

```python
quantity = fields.Integer(string='Quantity', default=1)
price = fields.Float(string='Price', digits=(10, 2))       # 10 celkovo, 2 desatinné
amount = fields.Monetary(string='Amount', currency_field='currency_id')
```

`Monetary` vyžaduje `currency_field` — názov M2O poľa na `res.currency` na tom istom modeli.

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

V DB sa ukladá VALUE (prvý element), zobrazuje sa LABEL (druhý).

### Relačné

```python
# Many2one — FK na iný model, ukladá integer ID
partner_id = fields.Many2one('res.partner', string='Partner', ondelete='restrict')

# One2many — virtuálny reverse, žiadny DB stĺpec
line_ids = fields.One2many('sale.order.line', 'order_id', string='Lines')

# Many2many — junction tabuľka
tag_ids = fields.Many2many(
    'product.tag',                # comodel
    'product_tag_rel',            # junction table (optional, auto-generated)
    'product_id',                 # column1 (optional)
    'tag_id',                     # column2 (optional)
    string='Tags'
)
```

**Junction table default naming**: alphabetical sort oboch model table names + `_rel`

### Binary / Image

```python
file_data = fields.Binary(string='File', attachment=True)   # uložené v ir.attachment
image = fields.Image(string='Image', max_width=1920, max_height=1920)
```

### Reference (polymorfné)

```python
document = fields.Reference([
    ('sale.order', 'Sales Order'),
    ('purchase.order', 'Purchase Order'),
], string='Document')
```

V DB: varchar `'sale.order,42'`. Žiadny FK constraint — orphaned references sa nečistia automaticky.

---

## Atribúty polí

### Bežné atribúty

| Atribút | Typ | Popis |
|---|---|---|
| string | str | Zobrazený label |
| required | bool | Povinné pole (default: False) |
| readonly | bool | Len na čítanie (default: False) |
| store | bool | Uložené v DB (default: True pre non-computed) |
| compute | str | Meno compute metódy |
| inverse | str | Meno inverse metódy (pre zapisovateľné computed) |
| related | str | Cesta cez relácie: `'partner_id.country_id'` |
| default | value/callable | Default hodnota alebo lambda |
| copy | bool | Kopírovať pri duplicate (default: True) |
| index | bool | DB index (default: False) |
| tracking | bool/int | Sledovanie zmien v chatter |
| groups | str | Viditeľnosť: `'base.group_system'` |
| help | str | Tooltip text |

### Špecifické pre M2O

| Atribút | Hodnoty | Popis |
|---|---|---|
| ondelete | 'set null' | Nastaví NULL (default) |
| | 'restrict' | Zakáže delete parent |
| | 'cascade' | Zmaže aj child |

**GOTCHA**: `required=True` + `ondelete='set null'` = **Registry Load Failure**! Vždy použi `restrict` alebo `cascade` s required M2O.

### Computed polia

```python
total = fields.Float(compute='_compute_total', store=True)

@api.depends('line_ids.price_subtotal')
def _compute_total(self):
    for record in self:
        record.total = sum(record.line_ids.mapped('price_subtotal'))
```

- `store=True` → uložené v DB, recomputed pri zmene depends
- `store=False` (default pre computed) → počítané on-the-fly, nesearchovateľné
- `inverse` → umožňuje write do computed poľa

### Related polia

```python
partner_country = fields.Char(related='partner_id.country_id.name', store=True)
```

- Shortcut pre jednoduchý compute cez relácie
- `store=True` → materialized v DB (rýchle search, ale treba recompute)
- `store=False` → vždy čerstvé, ale nesearchovateľné

---

## Syntax x2many commandov

### Tuple formát (legacy, stále funguje)

```python
# (command, id, values)
(0, 0, {'name': 'New'})           # CREATE — nový record s values
(1, id, {'name': 'Updated'})      # UPDATE — zmení existujúci record
(2, id, 0)                         # DELETE — zmaže record z DB
(3, id, 0)                         # UNLINK — odpojí z relácie (bez delete)
(4, id, 0)                         # LINK — pridá existujúci record do relácie
(5, 0, 0)                          # CLEAR — odpojí všetky (M2M: unlink, O2M: delete)
(6, 0, [id1, id2, id3])           # REPLACE — nastaví presný set IDs
```

### Command trieda (v15+, preferovaný)

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

### Použitie

```python
# Create SO s riadkami
env['sale.order'].create({
    'partner_id': partner.id,
    'order_line': [
        Command.create({'product_id': 1, 'product_uom_qty': 5}),
        Command.create({'product_id': 2, 'product_uom_qty': 3}),
    ]
})

# Update — pridaj riadok, zmeň existujúci, zmaž iný
order.write({
    'order_line': [
        Command.create({'product_id': 3, 'product_uom_qty': 1}),
        Command.update(line_id, {'product_uom_qty': 10}),
        Command.delete(old_line_id),
    ]
})

# M2M — groups na user
user.write({
    'groups_id': [
        Command.link(group_id),              # pridaj group
        # ALEBO
        Command.set([g1, g2, g3]),           # nahraď všetky
    ]
})
```

### V safe_eval (server actions)

V Odoo 17+ safe_eval kontexte je `Command` dostupný:

```python
# V automated action kóde:
record.write({'tag_ids': [Command.link(tag_id)]})
```

Pre staršie verzie alebo ak Command nie je dostupný, použi tuple syntax:

```python
record.write({'tag_ids': [(4, tag_id, 0)]})
```

---

## Domain syntax

### Základná štruktúra

```python
domain = [('field_name', 'operator', value)]
```

### Operátory

| Operátor | Popis | Príklad |
|---|---|---|
| `=` | Rovná sa | `('state', '=', 'draft')` |
| `!=` | Nerovná sa | `('state', '!=', 'cancel')` |
| `>` | Väčšie | `('amount', '>', 1000)` |
| `>=` | Väčšie alebo rovné | `('date', '>=', '2025-01-01')` |
| `<` | Menšie | `('qty', '<', 0)` |
| `<=` | Menšie alebo rovné | `('date', '<=', '2025-12-31')` |
| `in` | V zozname | `('state', 'in', ['draft', 'sent'])` |
| `not in` | Nie v zozname | `('state', 'not in', ['cancel', 'done'])` |
| `like` | Case-sensitive, auto-wildcards | `('name', 'like', 'order')` → %order% |
| `ilike` | Case-insensitive, auto-wildcards | `('name', 'ilike', 'order')` |
| `=like` | Case-sensitive, presný pattern | `('name', '=like', 'SO%')` |
| `=ilike` | Case-insensitive, presný pattern | `('email', '=ilike', '%@gmail.com')` |
| `child_of` | Hierarchicky pod | `('department_id', 'child_of', parent_id)` |
| `parent_of` | Hierarchicky nad | `('location_id', 'parent_of', child_id)` |
| `any` | Aspoň jeden O2M match | `('line_ids', 'any', [('qty', '>', 0)])` |
| `not any` | Žiadny O2M match | `('line_ids', 'not any', [('qty', '>', 0)])` |

### Logické operátory (Polish notation)

```python
# Default: AND (implicitné medzi podmienkami)
[('state', '=', 'draft'), ('amount', '>', 100)]
# ≡ state=draft AND amount>100

# OR: prefix '|'
['|', ('state', '=', 'draft'), ('state', '=', 'sent')]
# ≡ state=draft OR state=sent

# NOT: prefix '!'
['!', ('active', '=', False)]
# ≡ NOT(active=False) → active je True

# Komplexné: (A AND B) OR C
['|', '&', ('state', '=', 'draft'), ('amount', '>', 100), ('priority', '=', 'high')]

# 3x OR: 2x '|' prefix
['|', '|', ('state', '=', 'a'), ('state', '=', 'b'), ('state', '=', 'c')]
# ≡ state=a OR state=b OR state=c
# Pravidlo: N podmienok s OR = N-1 operátorov '|'
```

### Gotchas

1. **Field-to-field compare NIE JE MOŽNÝ:**
   ```python
   # WRONG — nefunguje:
   [('date_done', '<=', 'commitment_date')]
   
   # FIX: stored computed helper field alebo Python code
   ```

2. **`!=` vylučuje False/NULL:**
   ```python
   # ('field', '!=', 'x') NEZAHŔŇA záznamy kde field je False
   # FIX:
   ['|', ('field', '=', False), ('field', '!=', 'x')]
   ```

3. **O2M domény sú limitované:**
   ```python
   # Simple O2M domain funguje pre ANY:
   [('line_ids.product_id', '=', product_id)]
   # → "aspoň jeden riadok má tento produkt"
   
   # ALL riadky s podmienkou → nemožné v doméne, použi computed field
   ```

4. **`any` / `not any` operátory (v17+):**
   ```python
   # Nové v v17 — čistejšie ako path syntax:
   [('line_ids', 'any', [('state', '=', 'done')])]
   [('line_ids', 'not any', [('state', '=', 'cancel')])]
   ```

5. **Archived records:**
   ```python
   # active=False records sú SKRYTÉ by default v search!
   # Ak chceš vidieť aj archived:
   env['model'].with_context(active_test=False).search([...])
   ```

---

## Naming konvencie

### Štandardné Odoo konvencie

| Vzor | Popis | Príklady |
|---|---|---|
| `*_id` | Many2one | partner_id, company_id, user_id |
| `*_ids` | Many2many / One2many | tag_ids, line_ids, order_ids |
| `state` | Selection — workflow stav | draft/confirmed/done/cancel |
| `active` | Boolean — archiving | True = aktívny |
| `sequence` | Integer — poradie | Drag-drop ordering |
| `company_id` | M2O → res.company | Multi-company |
| `currency_id` | M2O → res.currency | Mena |

### Prefixy polí

| Prefix | Zdroj | Príklad |
|---|---|---|
| (žiadny) | Module kód | `partner_id`, `state` |
| `x_` | Vytvorené cez UI (Technical) | `x_custom_field` |
| `x_studio_` | Vytvorené cez Studio | `x_studio_priority` |

### Gotcha: Studio field suffix

Ak zmažeš a znovuvytvoríš Studio field → `x_studio_field_1` (nie pôvodný názov).
VŽDY over Technical Name pred použitím v doméne/kóde.

### Pomenovanie modelov

```
module.model_name      # Bodková notácia (Python)
module_model_name      # Podčiarkovníková notácia (DB tabuľka)

sale.order       → sale_order (tabuľka)
sale.order.line  → sale_order_line (tabuľka)
res.partner      → res_partner (tabuľka)
```

### Konvencia XML ID

```
module.category_model_name   # Typický formát
base.group_user              # Group: base modul, group_user
sale.action_quotations_with_onboarding  # Window action
```
