---
title: Odoo 15 — Version Notes
domain: changelog
version: 15.0
edition: community
source: legacy
status: active
---

# Odoo 15 — Version Notes

## Breaking Changes from v14

### Removal of @api.multi
The `@api.multi` and `@api.one` decorators were removed. All methods are now assumed to work on recordsets (multi-record aware) by default.
```python
# v14 (Old)
@api.multi
def action_confirm(self):
    pass

# v15 (New)
def action_confirm(self):
    pass
```

### field track_visibility Deprecated
The `track_visibility` parameter was deprecated in favor of `tracking=True`.
```python
# v14 (Old)
name = fields.Char(track_visibility='onchange')

# v15 (New)
name = fields.Char(tracking=True)
```

## New Frontend Framework: OWL 1.x
Odoo 15 marks the transition to the Odoo Window Library (OWL) framework for new components.

```javascript
/** @odoo-module **/
const { Component, useState } = owl;

class MyComponent extends Component {
    setup() {
        this.state = useState({ count: 0 });
    }
}
MyComponent.template = 'my_module.MyComponent';
```

## Migration Patterns (14.0 → 15.0)

| Feature | Odoo 14 | Odoo 15 |
|---------|---------|---------|
| Decorator | `@api.multi` | Removed |
| Tracking | `track_visibility='onchange'` | `tracking=True` |
| Python Super | `super(Class, self).method()` | `super().method()` |
| JS Assets | `xml` in manifest `data` | `assets` dictionary |
| Chatter Widgets | Required `widget="..."` | Auto-detected |

## Preparing for v16
- **Batch Create**: Start using `@api.model_create_multi` for performance.
- **Python 3.9**: Ensure compatibility with Python 3.8 and 3.9.
- **OWL Components**: Prefer OWL over legacy JS widgets for new development.
