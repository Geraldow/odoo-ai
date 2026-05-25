---
title: Production Checklist
domain: devops
version: 18.0
edition: both
source: native
status: active
---

# Production Checklist

Before going live with an Odoo 18 instance, ensure all these points are covered.

## Infrastructure & Security

- [ ] **SSL/TLS**: Ensure HTTPS is enforced (Let's Encrypt, Nginx/Apache).
- [ ] **Admin Password**: Change the default master password (`admin_passwd` in `odoo.conf`).
- [ ] **Database Manager**: Disable the database manager (`list_db = False`).
- [ ] **Firewall**: Restrict PostgreSQL port (5432) to localhost or trusted IPs only.

## Performance Tuning

- [ ] **Workers**: Enable multi-processing by setting `workers` (Rule of thumb: `(CPU * 2) + 1`).
- [ ] **Memory Limits**: Set `limit_memory_soft` and `limit_memory_hard` based on available RAM.
- [ ] **PostgreSQL**: Optimize `postgresql.conf` (shared_buffers, effective_cache_size).

## Backup Strategy

- [ ] **Automated Backups**: Daily backups of the database AND the filestore.
- [ ] **Off-site Storage**: Store backups on a separate server or S3-compatible storage.
- [ ] **Restore Test**: Periodically test a full restoration process.

## Odoo Configuration

- [ ] **Longpolling**: Ensure the longpolling port (8072) is correctly proxied by Nginx.
- [ ] **Proxy Mode**: Enable `proxy_mode = True` in `odoo.conf` when behind a reverse proxy.
- [ ] **Log Rotation**: Configure system-level log rotation to prevent disk space exhaustion.

## Module Update Sequence

1. Back up the production database.
2. Deploy code to the server.
3. Update modules via command line: `odoo-bin -c /etc/odoo.conf -d production -u custom_module --stop-after-init`.
4. Restart the Odoo service.
