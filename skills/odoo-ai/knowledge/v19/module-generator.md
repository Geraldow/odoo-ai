---
title: Odoo 19 — Module Generator
domain: scaffold
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Module Generator

## Purpose
Module scaffolding and manifest structure for Odoo 19, emphasizing Python 3.12+ compatibility and new type hinting requirements.

## Manifest Changes
The `__manifest__.py` file in Odoo 19 remains structurally similar, but requires careful dependency management due to structural changes in core addons.

```python
{
    'name': 'My Odoo 19 Module',
    'version': '1.0',
    'category': 'Custom',
    'summary': 'Example Odoo 19 module scaffolding',
    'description': """
        Module description focusing on v19 patterns.
    """,
    'author': 'Your Company',
    'depends': ['base', 'web'],
    'data': [
        'security/ir.model.access.csv',
        'views/my_model_views.xml',
    ],
    'assets': {
        'web.assets_backend': [
            'my_module/static/src/components/**/*.js',
            'my_module/static/src/components/**/*.xml',
        ],
    },
    'installable': True,
    'application': False,
    'license': 'LGPL-3',
}
```

## Python 3.12+ Structure
All Python files should heavily leverage new typing features.

`__init__.py`:
```python
from . import models
from . import controllers
```

`models/__init__.py`:
```python
from . import my_model
```

`models/my_model.py`:
```python
from odoo import models, fields, api
from odoo.tools import SQL

class MyModel(models.Model):
    _name = 'my.model'
    _description = 'My Model'
    
    name = fields.Char()
    
    # New constraint syntax for v19
    _name_unique = models.Constraint(
        'UNIQUE(name)',
        'Name must be unique'
    )
```
