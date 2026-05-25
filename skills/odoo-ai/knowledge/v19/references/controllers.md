---
title: Odoo 19 — Controllers Reference
domain: http
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Controllers Reference

## Route Decorator (`@http.route`)

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `route` | `str/list` | URL path(s). |
| `type` | `str` | `http` (HTML/Files) or `json` (RPC). |
| `auth` | `str` | `user` (logged in), `public` (anyone), `none` (no db). |
| `methods` | `list` | Allowed HTTP methods (e.g., `['GET', 'POST']`). |
| `website` | `bool` | Enables website features (sessions, templates). |
| `csrf` | `bool` | Cross-Site Request Forgery protection. Default: `True`. |

```python
from odoo import http
from odoo.http import request

class MyController(http.Controller):
    @http.route('/my_api/hello', type='json', auth='user')
    def hello(self, name: str = 'World', **kwargs) -> dict:
        return {
            'message': f"Hello {name}",
            'user': request.env.user.name,
        }
```

## New: Interactive API Documentation
Odoo 19 includes the `api_doc` module.
- **Endpoint:** `/doc`
- **Feature:** Automatically generates interactive documentation for your controllers and model methods using an OpenAPI/Swagger interface.

## Request Object (`request`)

| Attribute | Description |
| :--- | :--- |
| `request.env` | The Odoo Environment. |
| `request.params` | Combined GET/POST parameters. |
| `request.session` | Current session data. |
| `request.render()` | Renders a QWeb template. |
| `request.redirect()` | Performs an HTTP redirect. |

## Authentication Modes
- **`user`:** Mandatory login. `request.env.user` is the current user.
- **`public`:** Open access. `request.env.user` defaults to the "Public User".
- **`none`:** No database access. Used for health checks or early-boot routes.

## Performance Note
Odoo 19 is optimized for **Python 3.12**, leveraging faster dictionary lookups which significantly improves controller response times when handling large JSON payloads.
