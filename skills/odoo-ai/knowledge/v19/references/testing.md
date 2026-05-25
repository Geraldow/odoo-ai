---
title: Odoo 19 — Testing Reference
domain: testing
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Testing Reference

Testing in Odoo 19 is vital for maintaining the integrity of business logic, security rules, and the modern UI.

## Core Test Classes

Odoo provides specialized base classes for different levels of testing.

| Class | Transaction Behavior | Typical Use Case |
|-------|----------------------|------------------|
| `TransactionCase` | Individual transaction per test, rolled back at end. | Standard backend logic and unit tests. |
| `SavepointCase` | One transaction for the whole class, savepoints per test. | High-volume unit tests (faster). |
| `HttpCase` | Browser-capable controller, full web stack. | UI Tours, website routes, and frontend logic. |

```python
from odoo.tests import TransactionCase, tagged

@tagged('post_install', '-at_install')
class TestMyModule(TransactionCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        # Setup class-wide test data
        cls.partner = cls.env['res.partner'].create({'name': 'Test Partner'})

    def test_logic(self):
        # Assert behavior
        self.assertEqual(self.partner.name, 'Test Partner')
```

## Tagging System (`@tagged`)

Tags control the execution environment and timing of tests.

- `standard`: The default tag for most tests.
- `at_install`: Executes immediately after the module is installed.
- `post_install`: Executes after the entire module set for the session is installed (preferred for cross-module logic).
- `-at_install`: Prevents the test from running in the `at_install` phase.
- `slow`: Excluded from default runs; requires explicit selection.

## Specialized Assertions

Beyond standard Python `unittest`, Odoo includes tools for recordset validation.

| Assertion | Description |
|-----------|-------------|
| `self.assertEqual(a, b)` | Standard equality check. |
| `self.assertRecordValues(records, [{'f1': v1}, ...])` | Validates multiple fields across multiple records in one call. |
| `with self.assertRaises(UserError):` | Confirms that a specific exception is raised by a block of code. |
| `self.assertIn(member, container)` | Checks if an element exists in a collection. |

## Executing Tests

Tests are triggered via the command line using the Odoo binary.

```bash
# Run tests for a specific module
python3 odoo-bin -u my_module --test-enable --stop-after-init

# Run tests with specific tags
python3 odoo-bin -u my_module --test-enable --test-tags post_install

# Run a specific test class
python3 odoo-bin -u my_module --test-enable --test-tags .TestMyModuleClass
```

## Frontend Tour Testing

UI tours simulate user interaction in the browser. They are defined in JavaScript and executed within an `HttpCase`.

```python
from odoo.tests import HttpCase, tagged

@tagged('post_install', '-at_install')
class TestTour(HttpCase):
    def test_my_tour(self):
        self.start_tour("/", "my_module.my_tour_name", login="admin")
```
