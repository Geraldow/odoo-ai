---
title: Odoo 18 — Testing Reference
domain: testing
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Testing Reference

Testing in Odoo 18 ensures stability across the ORM, business logic, and UI.

## Test Classes

Odoo provides several base classes for different testing scenarios.

| Class | Description |
|-------|-------------|
| `TransactionCase` | Each test runs in its own transaction, which is rolled back at the end. Recommended for most unit tests. |
| `SavepointCase` | The entire class runs in one transaction, using savepoints for each test. Faster for large test suites. |
| `HttpCase` | Used for testing HTTP routes and JavaScript tours. Includes a browser controller. |

```python
from odoo.tests import TransactionCase, tagged

@tagged('post_install', '-at_install')
class TestMyModule(TransactionCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.partner = cls.env['res.partner'].create({'name': 'Test Partner'})

    def test_logic(self):
        self.assertEqual(self.partner.name, 'Test Partner')
```

## @tagged Decorator

Used to categorize tests and control when they run.

- `standard`: Run by default.
- `at_install`: Run immediately after module installation (default).
- `post_install`: Run after all modules in the current installation batch are installed.
- `-at_install`: Do not run during `at_install` phase.
- `slow`: Excluded from default runs.

## Common Assertions

In addition to standard Python `unittest` assertions, Odoo provides specific ones for records.

| Assertion | Description |
|-----------|-------------|
| `self.assertEqual(a, b)` | Check if a equals b. |
| `self.assertTrue(x)` | Check if x is true. |
| `self.assertFalse(x)` | Check if x is false. |
| `self.assertRecordValues(records, [{'f1': v1}, ...])` | Efficiently check multiple fields on multiple records. |
| `with self.assertRaises(UserError):` | Assert that a specific error is raised. |

## Test Runner Commands

Run tests from the command line using `odoo-bin`.

```bash
# Run tests for a specific module
python3 odoo-bin -c odoo.conf -u my_module --test-enable --stop-after-init

# Run only specifically tagged tests
python3 odoo-bin -u my_module --test-enable --test-tags post_install

# Run a specific test class or method
python3 odoo-bin -u my_module --test-enable --test-tags .test_method_name
```

## Tour Testing

JS Tours are used to test the UI flow. Defined in Python and executed in `HttpCase`.

```python
def test_tour(self):
    self.start_tour("/", "my_module.my_tour_name", login="admin")
```
