---
title: Odoo 18 — Model Patterns
domain: models
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Model Patterns

## Purpose
ORM model patterns, field types, and compute decorators for Odoo 18.

## Version 18.0 Requirements
- **Python**: 3.10+ required, 3.12 recommended.
- **Type Hints**: Strongly recommended (will be mandatory in v19).
- **SQL Builder**: Use `SQL()` for raw SQL (mandatory in v19).
- **Company Check**: Use `_check_company_auto = True`.
- **Decorators**: `@api.model_create_multi` is mandatory for create methods.

## Model Definition (v18)

```python
# -*- coding: utf-8 -*-
from typing import Optional, Any
from odoo import api, fields, models, Command, _
from odoo.exceptions import UserError, ValidationError
from odoo.tools import SQL


class MyModel(models.Model):
    _name = 'my_module.my_model'
    _description = 'My Model'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'create_date desc'

    # v18: Enable automatic company consistency check
    _check_company_auto = True

    # === BASIC FIELDS === #
    name = fields.Char(
        string='Name',
        required=True,
        tracking=True,
    )
    active = fields.Boolean(default=True)
    sequence = fields.Integer(default=10)
    description = fields.Text(string='Description')

    # === RELATIONAL FIELDS === #
    company_id = fields.Many2one(
        comodel_name='res.company',
        string='Company',
        default=lambda self: self.env.company,
        required=True,
        index=True,
    )
    partner_id = fields.Many2one(
        comodel_name='res.partner',
        string='Partner',
        tracking=True,
        check_company=True,  # v18: Framework handles company validation
    )
    user_id = fields.Many2one(
        comodel_name='res.users',
        string='Responsible',
        default=lambda self: self.env.user,
        tracking=True,
        check_company=True,
    )
    line_ids = fields.One2many(
        comodel_name='my_module.my_model.line',
        inverse_name='parent_id',
        string='Lines',
        copy=True,
    )
    tag_ids = fields.Many2many(
        comodel_name='my_module.tag',
        string='Tags',
    )

    # === SELECTION FIELDS === #
    state = fields.Selection(
        selection=[
            ('draft', 'Draft'),
            ('confirmed', 'Confirmed'),
            ('done', 'Done'),
            ('cancelled', 'Cancelled'),
        ],
        string='Status',
        default='draft',
        required=True,
        tracking=True,
        copy=False,
    )

    # === MONETARY FIELDS === #
    currency_id = fields.Many2one(
        comodel_name='res.currency',
        string='Currency',
        default=lambda self: self.env.company.currency_id,
        required=True,
    )
    amount = fields.Monetary(
        string='Amount',
        currency_field='currency_id',
    )

    # === COMPUTED FIELDS === #
    total_amount = fields.Float(
        string='Total Amount',
        compute='_compute_total_amount',
        store=True,
    )

    @api.depends('line_ids.amount')
    def _compute_total_amount(self) -> None:
        """Compute total from lines with type hints."""
        for record in self:
            record.total_amount = sum(record.line_ids.mapped('amount'))

    # === CONSTRAINTS === #
    @api.constrains('amount')
    def _check_amount(self) -> None:
        """Validate amount is positive."""
        for record in self:
            if record.amount < 0:
                raise ValidationError(_("Amount must be positive."))

    _sql_constraints = [
        ('name_uniq', 'unique(company_id, name)', 'Name must be unique per company!'),
    ]

    # === CRUD METHODS === #
    @api.model_create_multi
    def create(self, vals_list: list[dict[str, Any]]) -> 'MyModel':
        """Override create using mandatory multi-create pattern."""
        for vals in vals_list:
            if not vals.get('name'):
                vals['name'] = self.env['ir.sequence'].next_by_code(
                    'my_module.my_model'
                ) or _('New')
        return super().create(vals_list)

    def write(self, vals: dict[str, Any]) -> bool:
        """Override write with validation."""
        if 'state' in vals and vals['state'] == 'done':
            for record in self:
                if not record.line_ids:
                    raise UserError(_("Cannot complete without lines."))
        return super().write(vals)

    # === x2many OPERATIONS - Use Command class === #
    def action_update_lines(self) -> None:
        """Standard Command usage for relational fields."""
        self.write({
            'line_ids': [
                Command.create({'name': 'New Line', 'amount': 100}), # Create
                Command.update(self.line_ids[0].id, {'amount': 200}), # Update
                Command.delete(self.line_ids[1].id), # Delete from DB
                Command.unlink(self.line_ids[2].id), # Remove relation
                Command.clear(), # Clear all relations
            ]
        })

    # === SQL BUILDER PATTERN === #
    def _get_report_data(self) -> list[dict[str, Any]]:
        """Use SQL() for safe, type-aware query building."""
        query = SQL(
            """
            SELECT m.id, m.name, SUM(l.amount) as total
            FROM %s m
            LEFT JOIN %s l ON l.parent_id = m.id
            WHERE m.company_id = %s
            GROUP BY m.id, m.name
            """,
            SQL.identifier(self._table),
            SQL.identifier('my_module_my_model_line'),
            self.env.company.id,
        )
        self.env.cr.execute(query)
        return self.env.cr.dictfetchall()
```

## Automatic Company Validation
In Odoo 18, the framework can handle company consistency checks automatically between a record and its relational fields.

```python
class MyModel(models.Model):
    _name = 'my.model'
    _check_company_auto = True  # Enable automatic checking

    company_id = fields.Many2one('res.company', required=True)
    partner_id = fields.Many2one(
        'res.partner',
        check_company=True,  # Framework handles validation
    )
```

## Inheritance Patterns

### Classical Inheritance (Extension)
```python
class ResPartner(models.Model):
    _inherit = 'res.partner'

    custom_field = fields.Char(string='Custom Field')

    @api.model_create_multi
    def create(self, vals_list: list[dict[str, Any]]) -> 'ResPartner':
        return super().create(vals_list)
```

### Abstract Model (Mixin)
```python
class ApprovalMixin(models.AbstractModel):
    _name = 'my_module.approval.mixin'
    _description = 'Approval Logic'

    approval_state = fields.Selection([
        ('pending', 'Pending'),
        ('approved', 'Approved'),
    ], default='pending', tracking=True)

    def action_approve(self) -> None:
        self.write({'approval_state': 'approved'})
```

## Transient Model (Wizard)

```python
class MyWizard(models.TransientModel):
    _name = 'my_module.wizard'
    _description = 'Batch Update Wizard'

    record_ids = fields.Many2many('my_module.my_model', string='Records')
    new_state = fields.Selection([('done', 'Done')], required=True)

    def action_apply(self) -> dict[str, Any]:
        self.record_ids.write({'state': self.new_state})
        return {'type': 'ir.actions.act_window_close'}
```

## Migration: 17.0 → 18.0 Summary

| Feature | v17 | v18 | Recommendation |
|---------|-----|-----|----------------|
| `_check_company_auto` | N/A | Available | Add to multi-company models |
| `SQL()` builder | N/A | Recommended | Use for all raw SQL |
| Type hints | Optional | Recommended | Add to methods |
| Record Rules | `company_id` in `company_ids` | `company_id` in `allowed_company_ids` | Update XML rules |

## v18 Decorator Reference

| Decorator | Usage |
|-----------|-------|
| `@api.model` | Method without recordset (static-like) |
| `@api.model_create_multi` | Mandatory for `create` |
| `@api.depends(*fields)` | Compute field dependencies |
| `@api.constrains(*fields)` | Python-side validation |
| `@api.onchange(*fields)` | UI-only dynamic updates |
| `@api.depends_context(*keys)` | Context-dependent computes |

## v18 Checklist
- [ ] Set `_check_company_auto = True` for models with `company_id`.
- [ ] Use `check_company=True` on relational fields.
- [ ] Use `@api.model_create_multi` for `create`.
- [ ] Replace raw SQL strings with `SQL()` builder.
- [ ] Apply type hints to method signatures.
- [ ] Use `Command` for all x2many manipulations.
- [ ] Use `allowed_company_ids` in Record Rules.

## AI Agent Instructions
When generating Odoo 18.0 models:
1. **Always** include `_check_company_auto = True` for multi-company models.
2. **Always** use `@api.model_create_multi` for create methods.
3. **Use** `check_company=True` on Many2one/Many2many fields.
4. **Use** `SQL()` and `SQL.identifier()` for any raw database operations.
5. **Implement** Python type hints in all new methods.
6. **Prefer** `Command` class over legacy `(0, 0, vals)` tuples.
