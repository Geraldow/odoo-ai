---
title: Common Test Cases
domain: testing
version: 18.0
edition: both
source: native
status: active
---

# Common Test Cases

## Basic Model Tests

```python
# tests/test_my_model.py
from odoo.tests import tagged
from odoo.exceptions import ValidationError, UserError
from .common import TestMyModuleCommon


@tagged('post_install', '-at_install')
class TestMyModel(TestMyModuleCommon):
    """Unit tests for my.model"""

    def test_create_record(self):
        """Test basic record creation"""
        record = self.env['my.model'].create({
            'name': 'Test Record',
            'partner_id': self.partner.id,
        })
        self.assertTrue(record.id)
        self.assertEqual(record.name, 'Test Record')
        self.assertEqual(record.state, 'draft')

    def test_state_workflow(self):
        """Test state transitions"""
        record = self.env['my.model'].create({
            'name': 'Workflow Test',
        })

        # Add required line for confirmation
        self.env['my.model.line'].create({
            'model_id': record.id,
            'name': 'Line 1',
            'quantity': 1,
        })

        # Test confirm
        self.assertEqual(record.state, 'draft')
        record.action_confirm()
        self.assertEqual(record.state, 'confirmed')
```

## Computed Field Tests

```python
@tagged('post_install', '-at_install')
class TestMyModelComputed(TestMyModuleCommon):
    """Test computed fields"""

    def test_compute_total(self):
        """Test total computation"""
        record = self.env['my.model'].create({
            'name': 'Computed Test',
        })

        # Create lines
        self.env['my.model.line'].create({
            'model_id': record.id,
            'name': 'Line 1',
            'quantity': 2,
            'price_unit': 10.0,
        })
        self.env['my.model.line'].create({
            'model_id': record.id,
            'name': 'Line 2',
            'quantity': 3,
            'price_unit': 20.0,
        })

        # Total should be (2*10) + (3*20) = 80
        self.assertEqual(record.total_amount, 80.0)
```

## Security Tests

```python
# tests/test_security.py
from odoo.tests import tagged
from odoo.exceptions import AccessError
from .common import TestMyModuleCommon

@tagged('post_install', '-at_install')
class TestMyModelSecurity(TestMyModuleCommon):
    """Security and access rights tests"""

    def test_user_can_read_own_records(self):
        """Test basic user can read their own records"""
        record = self.env['my.model'].with_user(self.user_basic).create({
            'name': 'User Record',
        })
        # Should be able to read
        record.with_user(self.user_basic).read(['name'])

    def test_user_cannot_delete(self):
        """Test basic user cannot delete records"""
        record = self.env['my.model'].create({'name': 'Test'})
        with self.assertRaises(AccessError):
            record.with_user(self.user_basic).unlink()
```

## Multi-Company Testing (v18+)

```python
def test_check_company_auto(self):
    """Test automatic company checking (v18+)"""
    # Create partner in different company
    company2 = self.env['res.company'].create({'name': 'Company 2'})
    partner_c2 = self.env['res.partner'].create({
        'name': 'Partner C2',
        'company_id': company2.id,
    })

    # Should raise if check_company=True
    with self.assertRaises(Exception):
        self.env['my.model'].create({
            'name': 'Cross Company',
            'company_id': self.company.id,
            'partner_id': partner_c2.id,  # Different company
        })
```

## Test Generation Checklist

- [ ] Basic CRUD operations (create, read, update, delete)
- [ ] All computed fields
- [ ] All constraints (Python and SQL)
- [ ] State workflow transitions
- [ ] Access rights by user group
- [ ] Record rules (multi-company, ownership)
- [ ] Onchange methods
- [ ] Action methods (buttons)
- [ ] Copy behavior
- [ ] Batch operations
