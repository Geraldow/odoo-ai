---
title: Playwright E2E Testing
domain: testing
version: 18.0
edition: both
source: native
status: active
---

# Playwright E2E Testing

## HTTP/Tour Tests

Odoo uses a built-in tour framework for end-to-end testing. While external tools like Playwright can be used, Odoo's native approach integrates deeply with the web client.

```python
# tests/test_ui.py
from odoo.tests import tagged, HttpCase


@tagged('post_install', '-at_install')
class TestMyModelUI(HttpCase):
    """UI/Tour tests"""

    def test_ui_create_record(self):
        """Test creating record via UI"""
        self.start_tour(
            '/web',
            'my_module_create_tour',
            login='admin',
        )
```

## Visibility Testing (v17+)

```python
def test_view_visibility(self):
    """Test view visibility conditions (v17+)"""
    record = self.env['my.model'].create({
        'name': 'Visibility Test',
        'state': 'draft',
    })

    # Get form view
    view = self.env['ir.ui.view'].search([
        ('model', '=', 'my.model'),
        ('type', '=', 'form'),
    ], limit=1)

    # In v17+, visibility uses Python expressions
    fields_view = self.env['my.model'].get_views(
        [(view.id, 'form')]
    )['views']['form']
    self.assertIn('invisible', str(fields_view))
```
