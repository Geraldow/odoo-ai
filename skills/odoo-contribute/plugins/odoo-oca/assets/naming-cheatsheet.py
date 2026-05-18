# OCA Naming Conventions — Cheatsheet
# Quick reference for odoo-oca skill

# =============================================================================
# MODULE NAMING
# =============================================================================
#
# Format: lowercase_with_underscores
# Prefix with domain or parent module name
#
# ✅ GOOD
#   sale_custom_report
#   hr_attendance_overtime
#   stock_picking_batch_extended
#
# ❌ BAD
#   SaleCustomReport          — no CamelCase
#   sale-custom-report        — no hyphens
#   my_module                 — too generic, no domain prefix
#   sale_custom_report_v2     — no version suffixes


# =============================================================================
# MODEL NAMING
# =============================================================================
#
# Format: dotted.lowercase matching module prefix
# _name and _description are REQUIRED
#
# ✅ GOOD
class SaleCustomReport(models.Model):
    _name = 'sale.custom.report'
    _description = 'Custom Sales Report'

# ❌ BAD — CamelCase in _name, missing _description
# class SaleCustomReport(models.Model):
#     _name = 'SaleCustomReport'


# =============================================================================
# FIELD NAMING
# =============================================================================
#
# Format: snake_case
# Suffixes convey type:
#   _id    → Many2one
#   _ids   → One2many / Many2many
#   _count → Integer (computed, count of related records)
#   _date  → Date / Datetime
#   _is_*  → Boolean (or prefix is_*)
#   _has_* → Boolean (or prefix has_*)
#
# ✅ GOOD
    partner_id = fields.Many2one('res.partner', string='Customer')
    line_ids = fields.One2many('sale.custom.report.line', 'report_id', string='Lines')
    tag_ids = fields.Many2many('sale.tag', string='Tags')
    line_count = fields.Integer(compute='_compute_line_count', string='# Lines')
    is_confirmed = fields.Boolean(string='Confirmed', default=False)
    confirmation_date = fields.Datetime(string='Confirmation Date')

# ❌ BAD
#   Partner = fields.Many2one(...)      — CamelCase
#   lines = fields.One2many(...)        — missing _ids suffix
#   nbr_lines = fields.Integer(...)     — use _count suffix
#   confirmed = fields.Boolean(...)     — prefer is_ prefix for clarity


# =============================================================================
# METHOD NAMING
# =============================================================================
#
# Prefixes define the method's role:
#
#   _compute_*    → @api.depends computed fields
#   _inverse_*    → inverse methods for computed fields
#   _search_*     → custom search for computed fields
#   _onchange_*   → @api.onchange handlers
#   _check_*      → @api.constrains validators
#   _action_*     → button actions (called from XML)
#   _prepare_*    → build value dicts for create/write
#   _get_*        → retrieve/calculate data (internal)
#   _create_*     → create related records (internal)
#   _send_*       → send emails/notifications
#
# Public methods (no underscore) are callable from XML buttons.
# Private methods (single underscore) are internal only.
#
# ✅ GOOD
    @api.depends('line_ids')
    def _compute_line_count(self):
        for rec in self:
            rec.line_count = len(rec.line_ids)

    @api.constrains('confirmation_date')
    def _check_confirmation_date(self):
        for rec in self:
            if rec.confirmation_date and rec.confirmation_date > fields.Datetime.now():
                raise ValidationError("Confirmation date cannot be in the future.")

    def action_confirm(self):
        """Public: called from XML button."""
        self.write({'is_confirmed': True, 'confirmation_date': fields.Datetime.now()})

    def _prepare_report_values(self):
        """Private: builds dict for report generation."""
        return {
            'partner_id': self.partner_id.id,
            'date': fields.Date.today(),
        }

# ❌ BAD
#   def compute_lines(self):        — missing _compute_ prefix
#   def on_change_partner(self):    — use _onchange_partner
#   def do_confirm(self):           — use action_confirm
#   def getValues(self):            — camelCase, use _get_values or _prepare_*


# =============================================================================
# CLASS NAMING (Python)
# =============================================================================
#
# Python class names: CamelCase (PEP 8), matching the dotted model name
#
# Model: sale.custom.report  →  class SaleCustomReport
# Model: hr.attendance.line  →  class HrAttendanceLine
#
# Inheritance class names: add suffix or clarify
# class SaleOrder(models.Model):          — extending sale.order
#     _inherit = 'sale.order'


# =============================================================================
# XML ID NAMING
# =============================================================================
#
# Format: {object_type}_{model_name}
#
# Views:     view_{model}_{view_type}    → view_sale_custom_report_form
# Actions:   action_{model}              → action_sale_custom_report
# Menus:     menu_{model}                → menu_sale_custom_report
# Groups:    group_{role}                → group_sale_manager
# Rules:     rule_{model}_{scope}        → rule_sale_custom_report_company
# Sequences: seq_{model}                → seq_sale_custom_report
# Data:      {model}_{identifier}        → sale_custom_report_template_default
