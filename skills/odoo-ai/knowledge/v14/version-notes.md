---
title: Odoo 14 — Version Notes
domain: changelog
version: 14.0
edition: community
source: legacy
status: active
---

# Odoo 14 — Version Notes

## Overview
Odoo 14 was released in October 2020. It is a Long Term Support (LTS) version.

## Key Technical Features
- **Implicit Recordset Iteration**: While `@api.multi` is still common, methods work on recordsets by default.
- **Python 3.6+**: No support for Python 2.
- **Improved Performance**: Significant optimizations in the ORM and client-side processing.
- **Search Panel**: New UI component for filtering records in tree views.

## Legacy Patterns (Still Primary in v14)
- **track_visibility**: Still the primary way to define field tracking in models.
- **@api.multi**: Explicitly used in most existing codebases.
- **attrs**: The only way to handle conditional field/button visibility in XML views.
- **Legacy JS Framework**: Widgets are built using `web.Widget` and registered via `core.action_registry`.

## Migration from v13 to v14
- **Removal of Python 2 code**: Ensure all codebase is Python 3 compatible.
- **Web Client Refactor**: Some JS APIs changed, requiring updates to custom widgets.
- **Manifest**: `open_days` and other CRM-specific fields changed logic.

## Forward Compatibility for v15
- **Stop using @api.multi**: Start writing methods without the decorator.
- **Use tracking=True**: Odoo 14 supports `tracking=True` as an alias for `track_visibility`, preparing for v15.
- **super()**: Use Python 3 style `super().method()` instead of `super(Class, self).method()`.
