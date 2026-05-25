---
title: Docker Setup Guide
domain: devops
version: 18.0
edition: both
source: native
status: active
---

# Docker Setup Guide

Odoo 18 requires PostgreSQL 13 or later. Docker is the preferred way to manage the complex dependencies of an Odoo environment.

## Docker Compose Setup

A standard `docker-compose.yml` for Odoo 18 development includes the Odoo service and a PostgreSQL database.

```yaml
services:
  web:
    image: odoo:18.0
    depends_on:
      - db
    ports:
      - "8069:8069"
    volumes:
      - odoo-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=odoo
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
    volumes:
      - odoo-db-data:/var/lib/postgresql/data

volumes:
  odoo-web-data:
  odoo-db-data:
```

## Volumes and Persistence

- **/var/lib/odoo**: Stores the filestore (attachments, images). Must be persisted.
- **/var/lib/postgresql/data**: The database files. Critical for data persistence.
- **/mnt/extra-addons**: Map your local custom modules here for development.

## Port Mapping

- **8069**: Standard Odoo web interface.
- **8072**: Long polling port (required for chat/notifications in production).

## Development vs Production

### Development
- Use `volumes` to mount your code for hot-reloading (though Odoo needs a restart or `-u` to pick up Python changes).
- Set `dev_mode = reload` in `odoo.conf` if using an external runner, but in Docker it's usually better to just use `-u` commands.

### Production
- Use specific image tags instead of `latest` or `18.0`.
- Use a robust `odoo.conf` with `workers` enabled.
- Ensure the `db` service is not exposed to the public internet.
- Implement automated backups for the PostgreSQL volume and the filestore.
