# ODSK-SKL-MODULE | References: Official Odoo Module Documentation

## Official Odoo Documentation

| Topic | URL |
|-------|-----|
| Module manifest (`__manifest__.py`) — v17 | https://www.odoo.com/documentation/17.0/developer/reference/backend/module.html |
| Module manifest (`__manifest__.py`) — v18 | https://www.odoo.com/documentation/18.0/developer/reference/backend/module.html |
| Module structure overview | https://www.odoo.com/documentation/17.0/developer/tutorials/server_framework_101/01_architecture.html |
| ORM — Models and Fields | https://www.odoo.com/documentation/17.0/developer/reference/backend/orm.html |

## OCA (Odoo Community Association)

| Topic | URL |
|-------|-----|
| OCA Guidelines — module structure | https://github.com/OCA/odoo-community.org/blob/master/website/Contribution/CONTRIBUTING.rst |
| OCA Conventions reference | https://odoo-community.org/page/contribute |

## Odoo Source Code (authoritative)

| Topic | File in odoo/odoo repo |
|-------|------------------------|
| Manifest parsing logic | `odoo/modules/module.py` — function `load_manifest()` |
| `addons_path` configuration | `odoo/tools/config.py` — option `addons_path` |
| Module auto-install logic | `odoo/modules/loading.py` — function `load_auto_install()` |

GitHub: https://github.com/odoo/odoo

## Version Compatibility Notes

| Field | v16 | v17 | v18 |
|-------|-----|-----|-----|
| `assets` bundle key in manifest | ✅ | ✅ | ✅ |
| `web.assets_backend` | ✅ | ✅ | ✅ |
| `sequence` field in manifest | ✅ | ✅ | ✅ |
| `currency` field in manifest | deprecated | ❌ | ❌ |

> For version-specific differences, see skills `odoo-v17-changes` and `odoo-v18-changes`.
