---
title: Server Commands Reference
domain: devops
version: 18.0
edition: both
source: native
status: active
---

# Server Commands Reference

The `odoo-bin` executable is the primary entry point for managing Odoo instances.

## Core Flags

- `-c <config_file>`: Specify the configuration file (default is `~/.odoorc`).
- `-d <database>`: Specify the database to use.
- `-i <modules>` / `--init <modules>`: Install one or more modules (comma-separated).
- `-u <modules>` / `--update <modules>`: Update one or more modules. Use `all` to update everything.

## Development and Debugging

- `--dev=all`: Enables developer mode features like auto-reload (Python), template inspection, and more.
- `--shell`: Starts Odoo in an interactive Python shell with the database environment loaded.
- `--log-level=<level>`: Set the logging level (`debug`, `info`, `warn`, `error`, `critical`).

## Testing Commands

- `--test-enable`: Enable unit tests to run during module installation/update.
- `--stop-after-init`: Stop the server immediately after the `-i` or `-u` operations finish. Usually used with tests.
- `--test-tags <tags>`: Filter which tests to run (e.g., `/module_name`, `standard`, `at_install`).

## Scaffolding

- `scaffold <name> [destination]`: Create a new module skeleton.
  ```bash
  python3 odoo-bin scaffold my_module ./addons
  ```

## Database Operations

- `--database-overwrite`: Force database overwrite during initialization.
- `--db-filter`: Regular expression to filter visible databases.
