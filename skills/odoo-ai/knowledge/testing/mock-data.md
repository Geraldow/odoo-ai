---
title: Test Mock Data
domain: testing
version: 18.0
edition: both
source: native
status: active
---

# Test Mock Data

## Common Test Setup

```python
# tests/common.py
from odoo.tests import TransactionCase, tagged

class TestMyModuleCommon(TransactionCase):
    """Common setup for all tests in this module"""

    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        # Create shared test data
        cls.company = cls.env.ref('base.main_company')
        cls.user_admin = cls.env.ref('base.user_admin')

        # Create test partner
        cls.partner = cls.env['res.partner'].create({
            'name': 'Test Partner',
            'email': 'test@example.com',
        })

        # Create test user with specific groups
        cls.user_manager = cls.env['res.users'].create({
            'name': 'Test Manager',
            'login': 'test_manager',
            'email': 'manager@example.com',
            'groups_id': [(6, 0, [
                cls.env.ref('base.group_user').id,
                cls.env.ref('my_module.group_manager').id,
            ])],
        })

        cls.user_basic = cls.env['res.users'].create({
            'name': 'Test User',
            'login': 'test_user',
            'email': 'user@example.com',
            'groups_id': [(6, 0, [
                cls.env.ref('base.group_user').id,
            ])],
        })
```

## Creation with Command Class (v16+)

```python
def test_create_with_command(self):
    """Test creation with Command class (v16+)"""
    from odoo.fields import Command

    record = self.env['my.model'].create({
        'name': 'Command Test',
        'line_ids': [
            Command.create({'name': 'Line 1', 'quantity': 1}),
            Command.create({'name': 'Line 2', 'quantity': 2}),
        ],
    })
    self.assertEqual(len(record.line_ids), 2)
```
