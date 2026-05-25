---
title: Odoo 18 — Controllers Reference
domain: http
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Controllers Reference

## Route Decorator (`@http.route`)

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `route` | `str/list` | URL path(s) for the controller. |
| `type` | `str` | `http` (Standard web) or `json` (JSON-RPC). |
| `auth` | `str` | `user` (logged in), `public` (anyone), `none` (no env). |
| `methods` | `list` | Allowed HTTP methods (e.g., `['POST']`). |
| `website` | `bool` | `True` if route should be published on website. |
| `csrf` | `bool` | Enable/Disable CSRF protection. Default: `True`. |
| `cors` | `str` | CORS settings. |

```python
from odoo import http
from odoo.http import request

class MyController(http.Controller):
    @http.route('/my_module/hello', type='http', auth='public', website=True)
    def hello_world(self, **kwargs):
        return request.render('my_module.hello_template', {
            'name': kwargs.get('name', 'World'),
        })
```

## Request Object (`request`)

| Attribute/Method | Description |
| :--- | :--- |
| `request.env` | The Odoo environment. |
| `request.params` | Merged GET and POST parameters. |
| `request.session` | Current user session. |
| `request.render()` | Renders a QWeb template (returns HTML). |
| `request.make_response()` | Creates a custom HTTP response. |
| `request.redirect()` | Redirects to another URL. |

## Auth Types

- `user`: Requires a valid user session. `request.env.user` is available.
- `public`: Available to everyone. If not logged in, `user` is the Public User.
- `none`: No database/environment initialization. Used for low-level system routes.

## JSON Routes
```python
@http.route('/api/get_data', type='json', auth='user')
def get_data(self, **kwargs):
    records = request.env['my.model'].search_read([], ['name', 'value'])
    return {
        'status': 'success',
        'data': records,
    }
```
