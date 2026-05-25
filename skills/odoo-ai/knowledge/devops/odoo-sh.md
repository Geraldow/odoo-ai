---
title: Odoo.sh Guide
domain: devops
version: 18.0
edition: enterprise
source: native
status: active
---

# Odoo.sh Guide

Odoo.sh is a PaaS (Platform as a Service) specifically designed for Odoo deployments.

## Branch Types

- **Production**: The live instance. Linked to the `master` or `main` branch. Only one production branch per project.
- **Staging**: Used for testing features with real production data. It creates a copy of the production database.
- **Development**: Used for unit testing and development. Uses a clean database or a manual dump.

## Build Process and Hooks

Every push to the repository triggers a "build".
- **Pre-install hooks**: Executed before the modules are installed.
- **Post-install hooks**: Executed after installation.
- Odoo.sh automatically runs tests if the `test-enable` flag is set in the configuration.

## Custom Domains

- Production branches can be mapped to custom domains (e.g., `www.yourcompany.com`).
- Odoo.sh provides free SSL certificates via Let's Encrypt.

## Tools and Access

- **SSH Access**: You can SSH into any build to inspect files or run `odoo-bin` commands.
- **Log Inspection**: Real-time logs are available via the web dashboard.
- **Shell**: A web-based terminal is available for quick commands.
- **PostgreSQL Editor**: Access to the database via `psql` or a web interface.

## Staging vs Production

| Feature | Staging | Production |
| :--- | :--- | :--- |
| Database | Copy of Production | Live Data |
| Emails | Intercepted/Disabled | Active |
| Cron Jobs | Disabled by default | Active |
| Custom URL | `<branch>-<project>.odoo.com` | Custom Domain |
