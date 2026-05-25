---
title: Deployment Patterns
domain: devops
version: 18.0
edition: both
source: native
status: active
---

# Deployment Patterns

Reliable strategies for updating Odoo instances.

## Zero-Downtime Updates

True zero-downtime is difficult with Odoo due to database schema changes, but can be approximated:
- **Nginx Maintenance Page**: Briefly redirect traffic while the service restarts.
- **Blue-Green Deployment**: Spin up a new version (Green) alongside the old one (Blue). Switch traffic at the load balancer once verified. (Requires compatible database changes or a temporary read-only state).

## Rolling Updates

Used in containerized environments like Kubernetes.
- Update one pod at a time.
- Requires that code changes are backward compatible with the current database schema.

## Rollback Strategy

Always have a plan to go back:
- **Snapshotting**: Take a VM or Database snapshot before major updates.
- **Git Revert**: Revert code to the previous stable commit.
- **Database Point-in-Time Recovery (PITR)**: Use WAL logs to restore the database to a specific second.

## Staging Workflow

1. Push code to `develop` branch.
2. CI runs tests.
3. Deploy to **Staging** (which has a fresh copy of Production data).
4. Functional validation by users.
5. Merge to `main` and deploy to **Production**.
