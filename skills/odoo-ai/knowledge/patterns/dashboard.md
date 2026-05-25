---
title: Dashboard & KPI Patterns
domain: patterns
version: all
edition: both
source: fhidalgo+peterurban+ahmedlakos
status: active
---

# Dashboard & KPI Patterns

## Dashboard Model (Pivot/Graph Base)

### Analytics Model for Reporting
```python
from odoo import api, fields, models, tools


class SaleAnalysis(models.Model):
    _name = 'sale.analysis'
    _description = 'Sales Analysis'
    _auto = False  # No table created - it's a database view
    _order = 'date desc'

    # Dimension fields
    date = fields.Date(string='Date', readonly=True)
    partner_id = fields.Many2one('res.partner', string='Customer', readonly=True)
    product_id = fields.Many2one('product.product', string='Product', readonly=True)
    categ_id = fields.Many2one('product.category', string='Category', readonly=True)
    user_id = fields.Many2one('res.users', string='Salesperson', readonly=True)
    state = fields.Selection([
        ('draft', 'Draft'),
        ('sale', 'Confirmed'),
        ('done', 'Done'),
        ('cancel', 'Cancelled'),
    ], string='Status', readonly=True)

    # Measure fields
    order_count = fields.Integer(string='# Orders', readonly=True)
    product_qty = fields.Float(string='Qty Sold', readonly=True)
    price_total = fields.Float(string='Total', readonly=True)

    def init(self):
        """Create database view for analysis."""
        tools.drop_view_if_exists(self.env.cr, self._table)
        self.env.cr.execute("""
            CREATE OR REPLACE VIEW %s AS (
                SELECT
                    row_number() OVER () as id,
                    so.date_order::date as date,
                    so.partner_id,
                    sol.product_id,
                    pt.categ_id,
                    so.user_id,
                    so.state,
                    COUNT(DISTINCT so.id) as order_count,
                    SUM(sol.product_uom_qty) as product_qty,
                    SUM(sol.price_total) as price_total
                FROM sale_order so
                JOIN sale_order_line sol ON sol.order_id = so.id
                JOIN product_product pp ON pp.id = sol.product_id
                JOIN product_template pt ON pt.id = pp.product_tmpl_id
                GROUP BY
                    so.date_order::date,
                    so.partner_id,
                    sol.product_id,
                    pt.categ_id,
                    so.user_id,
                    so.state
            )
        """ % self._table)
```

---

## Dashboard Views

### Pivot View
```xml
<record id="sale_analysis_view_pivot" model="ir.ui.view">
    <field name="name">sale.analysis.pivot</field>
    <field name="model">sale.analysis</field>
    <field name="arch" type="xml">
        <pivot string="Sales Analysis" display_quantity="true">
            <field name="date" type="row" interval="month"/>
            <field name="categ_id" type="row"/>
            <field name="user_id" type="col"/>
            <field name="price_total" type="measure"/>
            <field name="product_qty" type="measure"/>
            <field name="order_count" type="measure"/>
        </pivot>
    </field>
</record>
```

### Graph View
```xml
<record id="sale_analysis_view_graph" model="ir.ui.view">
    <field name="name">sale.analysis.graph</field>
    <field name="model">sale.analysis</field>
    <field name="arch" type="xml">
        <graph string="Sales Analysis" type="bar" stacked="True">
            <field name="date" type="row" interval="month"/>
            <field name="price_total" type="measure"/>
        </graph>
    </field>
</record>
```
