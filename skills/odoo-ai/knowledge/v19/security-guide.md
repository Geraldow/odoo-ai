---
title: Odoo 19 — Security Guide
domain: security
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Security Guide

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  ODOO 19.0 SECURITY PATTERNS                                                 ║
║  Mandatory Type Hints | SQL Builder | check_access | allowed_company_ids     ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## Security Groups (XML)

Standard group definition remains consistent with prior versions, used for categorizing access levels.

```xml
<record id="module_category_custom" model="ir.module.category">
    <field name="name">Custom Module</field>
    <field name="sequence">100</field>
</record>

<record id="group_custom_user" model="res.groups">
    <field name="name">User</field>
    <field name="category_id" ref="module_category_custom"/>
</record>

<record id="group_custom_manager" model="res.groups">
    <field name="name">Manager</field>
    <field name="category_id" ref="module_category_custom"/>
    <field name="implied_ids" eval="[(4, ref('group_custom_user'))]"/>
</record>
```

## Access Rights (CSV)

Stored in `security/ir.model.access.csv`.

```csv
id,name,model_id:id,group_id:id,perm_read,perm_write,perm_create,perm_unlink
access_custom_model_user,custom.model.user,model_custom_model,group_custom_user,1,1,1,0
access_custom_model_manager,custom.model.manager,model_custom_model,group_custom_manager,1,1,1,1
```

## Record Rules (v19 Syntax)

### Multi-Company Rule
V19 continues to use `allowed_company_ids` for global multi-company filtering.

```xml
<record id="rule_custom_model_multi_company" model="ir.rule">
    <field name="name">Custom Model: Multi-Company</field>
    <field name="model_id" ref="model_custom_model"/>
    <field name="global" eval="True"/>
    <field name="domain_force">[
        '|',
        ('company_id', '=', False),
        ('company_id', 'in', allowed_company_ids)
    ]</field>
</record>
```

### Domain-Based Rules
```xml
<record id="rule_custom_model_user_own" model="ir.rule">
    <field name="name">Custom Model: Own Records Only</field>
    <field name="model_id" ref="model_custom_model"/>
    <field name="domain_force">[('create_uid', '=', user.id)]</field>
    <field name="groups" eval="[(4, ref('group_custom_user'))]"/>
</record>
```

## Python Model Security

### Mandatory Type Hints & Imports
Odoo 19 requires `from __future__ import annotations` and explicit type hints for all field definitions and public methods.

```python
from __future__ import annotations
from odoo import api, fields, models, _
from odoo.exceptions import AccessError

class SecureModel(models.Model):
    _name = 'custom.secure'
    _description = 'Secure Model'
    _check_company_auto = True  # Automatic validation of company consistency

    name = fields.Char(required=True)
    company_id = fields.Many2one(
        'res.company',
        default=lambda self: self.env.company,
        required=True,
    )

    partner_id = fields.Many2one('res.partner', check_company=True)

    def action_sensitive_op(self) -> bool:
        """v19: check_access replaces check_access_rights."""
        self.check_access('write')
        self.check_access_rule('write')
        
        if not self.env.user.has_group('custom_module.group_custom_manager'):
            raise AccessError(_("Only managers can perform this."))
            
        return True
```

### Mandatory SQL Builder
All raw SQL queries must use the `SQL` builder. String interpolation or direct string queries are deprecated/prohibited.

```python
from odoo.tools import SQL

def _get_secure_stats(self) -> list[dict]:
    query = SQL(
        """
        SELECT state, COUNT(*) 
        FROM %(table)s 
        WHERE company_id = %(company_id)s
        GROUP BY state
        """,
        table=SQL.identifier(self._table),
        company_id=self.env.company.id,
    )
    self.env.cr.execute(query)
    return self.env.cr.dictfetchall()
```

## View Security (v19)

### Inline Conditional Attributes
`attrs` is entirely removed. Use direct attributes with Python-like expressions.

```xml
<field name="sensitive_data" 
       invisible="not user_has_groups('custom_module.group_custom_manager')"
       readonly="state == 'done'"/>

<button name="action_approve"
        string="Approve"
        type="object"
        invisible="state != 'draft' or not user_has_groups('base.group_system')"/>
```

## Security Best Practices Checklist
- [ ] `from __future__ import annotations` in all Python files.
- [ ] Type hints for all fields and public methods.
- [ ] Use `SQL()` builder for all manual queries.
- [ ] Use `check_access('perm')` for manual permission checks.
- [ ] Use `_check_company_auto = True` on company-dependent models.
- [ ] Use `check_company=True` on relational fields.
- [ ] Use `allowed_company_ids` in record rule domains.
