---
title: Odoo 19 — Development Reference
domain: devtools
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Development Reference

The Odoo 19 development ecosystem includes several tools designed to streamline debugging, performance tuning, and module scaffolding.

## Developer Mode (Debug Mode)

Debug mode unlocks technical menus, field metadata (on hover), and advanced editing tools.

- **Standard**: Append `?debug=1` to the URL.
- **Assets**: Append `?debug=assets` to disable JS/CSS minification (essential for OWL/JS debugging).
- **Tests**: Append `?debug=tests` to see test-related UI elements.

## Technical Configuration Menu

Available under **Settings -> Technical** when debug mode is active. Key areas:
- **Database Structure**: Inspect models and fields directly.
- **User Interface**: Live-edit Views, Menu Items, and Window Actions.
- **Automation**: Manage Scheduled Actions (Crons) and Automated Actions (Webhook/Logic).
- **Sequences**: Configure number formats for invoices, orders, etc.

## The Odoo Shell

An interactive Python REPL with a pre-loaded Odoo environment. Ideal for data fixing and quick testing.

```bash
python3 odoo-bin shell -c odoo.conf -d my_database
```
**Available variables**:
- `self`, `env`: Standard Odoo environment.
- `cr`: Database cursor.
- `uid`: Current user ID (usually 1).

## Performance Profiling

Odoo 19 includes a built-in profiler to visualize execution bottlenecks.
1. Enable Debug Mode.
2. Click the **Bug Icon** (top right) -> **Toggle Profiler**.
3. Execute the slow action.
4. Click **Stop and results**.
5. Analyze the "Flamegraph" or "Table" view to find the slowest methods or SQL queries.

## Scaffolding Modules

Generate a standard module structure automatically.
```bash
python3 odoo-bin scaffold <module_name> <target_directory>
```
This creates the `__manifest__.py`, `models/`, `views/`, and `security/` boilerplate.

## Test Execution

Run automated tests from the terminal.
```bash
# Run all tests for a module
python3 odoo-bin -u my_module --test-enable --stop-after-init

# Run only specific tags (e.g., exclude slow tests)
python3 odoo-bin -u my_module --test-enable --test-tags='-slow'
```

## Essential Debugging Hooks

- **Python**: Use `breakpoint()` for an interactive debugger.
- **Logging**: `import logging; _logger = logging.getLogger(__name__); _logger.info("Values: %s", values)`
- **Frontend**: Use `debugger;` in JavaScript to pause execution in browser dev tools.
- **Network**: Monitor `JSON-RPC` calls in the browser's Network tab (endpoint `/web/dataset/call_kw`).
