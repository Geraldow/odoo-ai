---
title: Odoo 18 — Development Reference
domain: devtools
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Development Reference

Essential tools and techniques for Odoo 18 developers.

## Developer Mode (Debug Mode)

Activates technical features in the UI (metadata, view editing, field information).

- **Standard**: Append `?debug=1` to the URL.
- **With Assets**: Append `?debug=assets` (disables JS/CSS minification, useful for frontend debugging).
- **Via UI**: Settings -> General Settings -> Activate the developer mode.

## Technical Menu

When Debug Mode is active, a "Technical" menu appears in Settings, providing access to:
- **Views**: Edit XML definitions directly.
- **Sequences & Identifiers**: External IDs, sequences.
- **Automation**: Scheduled actions (crons), automated actions.
- **User Interface**: Menu items, window actions.

## Built-in Profiler

Analyze performance directly from the UI.
1. Enable Debug Mode.
2. Click the bug icon in the top right.
3. Select "Toggle Profiler".
4. Perform the action you want to analyze.
5. Click "Stop and results".

## The Odoo Shell

Interactive Python environment with a pre-configured Odoo environment (`self`, `env`, `cr`).

```bash
python3 odoo-bin shell -c odoo.conf -d my_database
```
Example usage:
```python
>>> self.env['res.partner'].search([])
res.partner(1, 2, 3, ...)
```

## Scaffold Command

Quickly create a new module structure.
```bash
python3 odoo-bin scaffold my_module_name path/to/addons
```

## Test Runner

Execute automated tests.
```bash
python3 odoo-bin -u my_module --test-enable --stop-after-init
```

## Debugging Tips

- **PDB/Breakpoint**: Use `breakpoint()` in Python 3.7+ to pause execution.
- **Logging**: Use `_logger.info("Message")` to print to the Odoo log file.
- **Network Tab**: Use browser dev tools to inspect RPC calls (`/web/dataset/call_kw`).
