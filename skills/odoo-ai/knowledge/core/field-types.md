---
title: Field Types Reference v14→v19
domain: core
version: all
edition: both
source: fhidalgo
status: active
---

# Field Types Reference v14→v19

## Purpose
Complete reference for all Odoo field types, including their attributes, use cases, and version-specific enhancements.

## Standard Field Types

### String Fields
- **Char**: Short text (VARCHAR).
  ```python
  name = fields.Char(string='Name', required=True, tracking=True)
  ```
- **Text**: Long text (TEXT).
  ```python
  notes = fields.Text(string='Notes', translate=True)
  ```
- **Html**: Rich text editor content.
  ```python
  content = fields.Html(string='Content', sanitize=True)
  ```

### Numeric Fields
- **Integer**: Whole numbers.
  ```python
  sequence = fields.Integer(default=10)
  ```
- **Float**: Decimal numbers. Use `digits` for precision.
  ```python
  qty = fields.Float(digits='Product Unit of Measure')
  ```
- **Monetary**: Currency amounts. **Requires** `currency_id`.
  ```python
  amount = fields.Monetary(currency_field='currency_id')
  ```

### Logical and Selection
- **Boolean**: True/False toggle.
  ```python
  active = fields.Boolean(default=True)
  ```
- **Selection**: Choice from a static list of tuples.
  ```python
  state = fields.Selection([('draft', 'Draft'), ('done', 'Done')], default='draft')
  ```

### Date and Time
- **Date**: Date only.
  ```python
  date_start = fields.Date(default=fields.Date.context_today)
  ```
- **Datetime**: Date with time.
  ```python
  last_call = fields.Datetime(default=fields.Datetime.now)
  ```

## Relational Fields

- **Many2one**: Relation to a single record in another model (FK).
  ```python
  partner_id = fields.Many2one('res.partner', string='Partner', check_company=True)
  ```
- **One2many**: Virtual relation representing the multiple side of a Many2one.
  ```python
  line_ids = fields.One2many('my.model.line', 'parent_id', string='Lines')
  ```
- **Many2many**: Relation to multiple records in another model (junction table).
  ```python
  tag_ids = fields.Many2many('res.partner.category', string='Tags')
  ```

## Computed and Related Fields

### Computed Fields
Values calculated dynamically. Set `store=True` to save them in the database.
```python
total = fields.Float(compute='_compute_total', store=True)

@api.depends('line_ids.amount')
def _compute_total(self):
    for record in self:
        record.total = sum(record.line_ids.mapped('amount'))
```

### Related Fields
Shortcut to a field in a related record.
```python
partner_email = fields.Char(related='partner_id.email', readonly=True)
```

## Common Field Attributes

| Attribute | Usage |
|-----------|-------|
| `string` | Human-readable label. |
| `required` | Database-level NOT NULL constraint. |
| `readonly` | UI-level edit restriction. |
| `index` | Creates a database index. |
| `tracking` | Log changes in the chatter (v15+). |
| `groups` | Restrict field visibility to specific security groups. |
| `copy` | Whether the field is copied when the record is duplicated. |
| `check_company`| Ensures company consistency (v18+). |

## Naming Conventions
- Many2one fields: `model_id` (e.g., `partner_id`).
- X2many fields: `model_ids` (e.g., `line_ids`).
- Boolean fields: `is_` or `has_` prefix (e.g., `is_active`).
- Count fields: `_count` suffix (e.g., `task_count`).

## Version-Specific Notes
- **v14**: `track_visibility` used instead of `tracking`.
- **v16**: Support for specialized index types (`btree`, `trigram`).
- **v18**: `check_company=True` is the standard for multi-company models.
- **v18+**: Type hints are recommended on **method signatures only** (e.g., `def create(self, vals_list: list[dict]) -> 'MyModel':`). Field declarations do NOT use variable annotations — `name = fields.Char(...)` is always correct; `name: str = fields.Char(...)` is not Odoo convention.
