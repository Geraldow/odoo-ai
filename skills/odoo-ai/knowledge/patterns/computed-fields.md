---
title: Computed Field Patterns
domain: patterns
version: all
edition: both
source: fhidalgo+peterurban+ahmedlakos
status: active
---

# Computed Field Patterns

## Basic Computed Fields

### Simple Computation
```python
from odoo import api, fields, models


class MyModel(models.Model):
    _name = 'my.model'

    first_name = fields.Char()
    last_name = fields.Char()

    # Basic computed field
    full_name = fields.Char(
        string='Full Name',
        compute='_compute_full_name',
    )

    @api.depends('first_name', 'last_name')
    def _compute_full_name(self):
        for record in self:
            parts = filter(None, [record.first_name, record.last_name])
            record.full_name = ' '.join(parts)
```

### Stored Computed Field
```python
class MyModel(models.Model):
    _name = 'my.model'

    quantity = fields.Float()
    price = fields.Float()

    # Stored - saved to database, recomputed on dependency change
    subtotal = fields.Float(
        string='Subtotal',
        compute='_compute_subtotal',
        store=True,
    )

    @api.depends('quantity', 'price')
    def _compute_subtotal(self):
        for record in self:
            record.subtotal = record.quantity * record.price
```

### Readonly vs Editable
```python
class MyModel(models.Model):
    _name = 'my.model'

    # Non-stored are always readonly
    calculated_value = fields.Float(compute='_compute_value')

    # Stored computed can be readonly (default) or editable
    total = fields.Float(
        compute='_compute_total',
        store=True,
        readonly=True,  # Default
    )

    # Editable stored computed (rare)
    adjustable_total = fields.Float(
        compute='_compute_adjustable_total',
        store=True,
        readonly=False,
    )
```

---

## Dependency Patterns

### Field Dependencies
```python
@api.depends('field1', 'field2', 'field3')
def _compute_value(self):
    for record in self:
        record.value = record.field1 + record.field2 + record.field3
```

### Related Field Dependencies
```python
@api.depends('partner_id.name', 'partner_id.email')
def _compute_partner_info(self):
    for record in self:
        record.partner_info = f"{record.partner_id.name} <{record.partner_id.email}>"
```

### One2many/Many2many Dependencies
```python
@api.depends('line_ids.amount', 'line_ids.quantity')
def _compute_total(self):
    for record in self:
        record.total = sum(
            line.amount * line.quantity
            for line in record.line_ids
        )
```

### Deep Dependencies
```python
@api.depends('order_id.partner_id.country_id.code')
def _compute_country_code(self):
    for record in self:
        record.country_code = record.order_id.partner_id.country_id.code or ''
```

### No Dependencies (Always Recompute)
```python
# Use for values that depend on external factors
@api.depends()
def _compute_current_date(self):
    for record in self:
        record.current_date = fields.Date.today()
```

---

## Inverse Methods

### Editable Computed Field
```python
class MyModel(models.Model):
    _name = 'my.model'

    unit_price = fields.Float()
    quantity = fields.Float(default=1.0)

    # Editable computed field with inverse
    total_price = fields.Float(
        string='Total Price',
        compute='_compute_total_price',
        inverse='_inverse_total_price',
    )

    @api.depends('unit_price', 'quantity')
    def _compute_total_price(self):
        for record in self:
            record.total_price = record.unit_price * record.quantity

    def _inverse_total_price(self):
        """When user edits total, recalculate unit price."""
        for record in self:
            if record.quantity:
                record.unit_price = record.total_price / record.quantity
```

### Inverse with Related
```python
class MyModel(models.Model):
    _name = 'my.model'

    partner_id = fields.Many2one('res.partner')

    # Editable related-like field
    partner_email = fields.Char(
        string='Partner Email',
        compute='_compute_partner_email',
        inverse='_inverse_partner_email',
    )

    @api.depends('partner_id.email')
    def _compute_partner_email(self):
        for record in self:
            record.partner_email = record.partner_id.email

    def _inverse_partner_email(self):
        for record in self:
            if record.partner_id:
                record.partner_id.email = record.partner_email
```

---

## Search Methods

### Custom Search Implementation
```python
class MyModel(models.Model):
    _name = 'my.model'

    amount = fields.Float()
    tax_rate = fields.Float(default=0.21)

    total_with_tax = fields.Float(
        string='Total with Tax',
        compute='_compute_total_with_tax',
        search='_search_total_with_tax',
    )

    @api.depends('amount', 'tax_rate')
    def _compute_total_with_tax(self):
        for record in self:
            record.total_with_tax = record.amount * (1 + record.tax_rate)

    def _search_total_with_tax(self, operator, value):
        """Enable searching on computed field."""
        # Convert the search to base fields
        if operator in ('=', '!=', '<', '<=', '>', '>='):
            # Search for records where amount * (1 + tax_rate) matches
            # Simplified: assume default tax_rate
            adjusted_value = value / 1.21
            return [('amount', operator, adjusted_value)]
        return []
```

### Search with SQL
```python
def _search_full_name(self, operator, value):
    """Search on concatenated fields."""
    if operator == 'ilike':
        return [
            '|',
            ('first_name', 'ilike', value),
            ('last_name', 'ilike', value),
        ]
    elif operator == '=':
        # Exact match on full name
        self.env.cr.execute("""
            SELECT id FROM my_model
            WHERE CONCAT(first_name, ' ', last_name) = %s
        """, (value,))
        ids = [r[0] for r in self.env.cr.fetchall()]
        return [('id', 'in', ids)]
    return []
```

---

## Common Computation Patterns

### Aggregations
```python
# Sum
@api.depends('line_ids.amount')
def _compute_total_amount(self):
    for record in self:
        record.total_amount = sum(record.line_ids.mapped('amount'))

# Count
@api.depends('line_ids')
def _compute_line_count(self):
    for record in self:
        record.line_count = len(record.line_ids)

# Average
@api.depends('line_ids.score')
def _compute_average_score(self):
    for record in self:
        scores = record.line_ids.mapped('score')
        record.average_score = sum(scores) / len(scores) if scores else 0
```

### Performance Optimization

### Batch Computation
```python
@api.depends('partner_id')
def _compute_partner_order_count(self):
    """Optimized: single query for all records."""
    if not self:
        return

    # Single query for all partners
    data = self.env['sale.order'].read_group(
        [('partner_id', 'in', self.mapped('partner_id').ids)],
        ['partner_id'],
        ['partner_id'],
    )
    counts = {d['partner_id'][0]: d['partner_id_count'] for d in data}

    for record in self:
        record.partner_order_count = counts.get(record.partner_id.id, 0)
```

### Prefetching
```python
@api.depends('line_ids.product_id.categ_id')
def _compute_categories(self):
    # Prefetch all products at once
    self.mapped('line_ids.product_id')

    for record in self:
        categories = record.line_ids.mapped('product_id.categ_id')
        record.category_names = ', '.join(categories.mapped('name'))
```
