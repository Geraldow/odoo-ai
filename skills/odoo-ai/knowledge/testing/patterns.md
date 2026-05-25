---
title: Testing Patterns
domain: testing
version: 18.0
edition: both
source: native
status: active
---

# Testing Patterns

## Test File Structure

```
{module_name}/
├── tests/
│   ├── __init__.py
│   ├── common.py              # Shared test data and base classes
│   ├── test_{model_name}.py   # Model unit tests
│   ├── test_security.py       # Security/access tests
│   └── test_integration.py    # Integration tests
```

## Test Class Hierarchy

```python
# tests/__init__.py
from . import test_my_model
from . import test_security
from . import test_integration
```

## Test Tags Reference

| Tag | Meaning |
|-----|---------|
| `post_install` | Run after module installation |
| `-at_install` | Don't run during installation |
| `standard` | Standard test (default) |
| `external` | Requires external services |

## Running Tests

```bash
# Run all tests for a module
./odoo-bin -d testdb -i my_module --test-enable --stop-after-init

# Run specific test class
./odoo-bin -d testdb --test-tags my_module.TestMyModel

# Run with coverage
coverage run ./odoo-bin -d testdb -i my_module --test-enable --stop-after-init
coverage report
```
