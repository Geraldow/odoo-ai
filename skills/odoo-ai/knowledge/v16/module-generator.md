---
title: Odoo 16 — Module Generator
domain: scaffold
version: 16.0
edition: community
source: legacy
status: active
---

# Odoo 16 — Module Generator

## Purpose
Module scaffolding and manifest structure for Odoo 16.

## Manifest Structure (v16)

```python
{
    'name': 'My Module',
    'version': '16.0.1.0.0',
    'category': 'Tools',
    'summary': 'Module summary',
    'author': 'Your Company',
    'website': 'https://yourwebsite.com',
    'license': 'LGPL-3',
    'depends': ['base', 'mail', 'web'],
    'data': [
        'security/security.xml',
        'security/ir.model.access.csv',
        'views/my_model_views.xml',
        'views/menu.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'my_module/static/src/**/*.js',
            'my_module/static/src/**/*.xml',
            'my_module/static/src/**/*.scss',
        ],
    },
    'installable': True,
    'application': False,
}
```

## Preparing for v17 (Migration Notes)

| Component | v16 Status | v17 Status | Action Required |
|-----------|------------|------------|-----------------|
| `attrs` attribute | Deprecated | **REMOVED** | Must migrate |
| `states` attribute | Deprecated | **REMOVED** | Must migrate |
| `@api.model_create_multi` | Recommended | **Mandatory** | Must add |

### Mandatory: @api.model_create_multi

In v16, it is strongly recommended to use `@api.model_create_multi` for create methods.

```python
# v16 (Recommended)
@api.model_create_multi
def create(self, vals_list):
    for vals in vals_list:
        if not vals.get('name'):
            vals['name'] = self.env['ir.sequence'].next_by_code('my.model')
    return super().create(vals_list)
```

### Conversion from states to invisible

```xml
<!-- v16 (Deprecated) -->
<field name="partner_id" states="draft,sent"/>

<!-- v16 Recommended / v17 Required -->
<field name="partner_id" invisible="state not in ('draft', 'sent')"/>
```
