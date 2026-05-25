---
title: Troubleshooting Guide
domain: devops
version: 18.0
edition: both
source: native
status: active
---

# Troubleshooting Guide

Common Odoo errors and their standard resolutions.

## Database Connectivity

**Error**: `psycopg2.OperationalError: connection to server at "localhost" (::1), port 5432 failed: Connection refused`
- **Cause**: PostgreSQL is not running or the host/port in `odoo.conf` is incorrect.
- **Fix**: Check PostgreSQL service status. In Docker, ensure the `db` service is up and `HOST` env variable is set to `db`.

## Module Load Failures

**Error**: `ModuleNotFoundError: No module named 'odoo.addons.custom_module'`
- **Cause**: The module is not in the `addons_path`.
- **Fix**: Check `odoo.conf` or the `--addons-path` flag. Ensure the directory containing `custom_module` is included.

## XML Parsing Errors

**Error**: `ParseError: "External ID not found in the system: module.xml_id"`
- **Cause**: Trying to reference a record that doesn't exist or is defined in a module not listed in `depends`.
- **Fix**: Check the `__manifest__.py` for missing dependencies. Verify the XML ID spelling.

## OWL Component Errors

**Error**: `TypeError: Cannot read properties of null (reading 'el')`
- **Cause**: Accessing the DOM element of a component before it's mounted or after it's destroyed.
- **Fix**: Use `onWillStart` or `onMounted` lifecycle hooks appropriately. Check for optional chaining `?.`.

## Memory and Performance

**Error**: `Worker (1234) reached memory limit`
- **Cause**: A process exceeded `limit_memory_soft` or `limit_memory_hard`.
- **Fix**: Optimize heavy loops, use `search_read` instead of `search` + `read`, or increase limits in `odoo.conf` (with caution).
