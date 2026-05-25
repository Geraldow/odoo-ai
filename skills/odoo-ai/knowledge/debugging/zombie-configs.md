---
title: Zombie Configuration Fixes
domain: debugging
version: 18.0
edition: both
source: native
status: active
---

# Zombie Configuration Fixes

## Detecting Orphan Data
Zombie records often occur when modules are uninstalled or updated incorrectly, leaving behind `ir.model.data` entries that point to non-existent records.

### Identifying Orphaned ir.model.data
```python
def find_orphaned_xml_ids(self):
    """Find XML IDs pointing to non-existent records."""
    self.env.cr.execute("""
        SELECT id, module, name, model, res_id 
        FROM ir_model_data 
        WHERE model NOT IN (SELECT model FROM ir_model)
    """)
    return self.env.cr.dictfetchall()
```

## Stale Config Parameters
Old configurations in `ir.config.parameter` can cause unexpected behavior if they are not cleaned up during module updates.

### Cleaning Stale Parameters
```python
def cleanup_stale_parameters(self):
    """Remove parameters that are no longer used by the module."""
    prefix = 'my_module.'
    expected_params = ['my_module.api_key', 'my_module.endpoint']
    
    params = self.env['ir.config.parameter'].sudo().search([
        ('key', '=like', f'{prefix}%'),
        ('key', 'not in', expected_params)
    ])
    params.unlink()
```

## Cache and Registry Inconsistencies
Sometimes Odoo's registry or cache gets out of sync, leading to "zombie" behavior where old code seems to still be running.

### Manual Registry Reload
If configuration changes aren't taking effect, you might need to force a registry reload (use with caution):
```python
# From the Odoo Shell
self.env.registry.setup_models(self.env.cr)
self.env.registry.signal_changes()
```

## Handling Orphan Views
Orphaned views (views with no parent or incorrect inheritance) can break the UI.

### Detecting Broken Inheritance
```python
def check_broken_views(self):
    """Find views inheriting from non-existent parents."""
    self.env.cr.execute("""
        SELECT id, name, xml_id 
        FROM ir_ui_view 
        WHERE inherit_id IS NOT NULL 
        AND inherit_id NOT IN (SELECT id FROM ir_ui_view)
    """)
    return self.env.cr.dictfetchall()
```
