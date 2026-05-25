---
title: JSON-RPC 2.0 API
domain: api
version: 18.0
edition: both
source: native
status: active
---

# JSON-RPC 2.0 API

## JSON-RPC Controllers
Odoo provides native support for JSON-RPC 2.0 via controllers using the `type='json'` route parameter.

### Basic JSON Endpoint
```python
from odoo import http
from odoo.http import request

class MyAPI(http.Controller):
    @http.route('/api/v1/records', type='json', auth='user')
    def list_records(self, domain=None, fields=None, limit=100):
        """JSON-RPC endpoint to list records."""
        domain = domain or []
        fields = fields or ['name', 'state']
        
        records = request.env['my.model'].search_read(
            domain, fields, limit=limit
        )
        return {
            'status': 'success',
            'count': len(records),
            'data': records,
        }
```

### JSON with Validation
```python
@http.route('/api/v1/create', type='json', auth='user')
def create_record(self, name, **kwargs):
    """Create a record with input validation."""
    if not name:
        return {'status': 'error', 'message': 'Name is required'}
    
    try:
        record = request.env['my.model'].create({'name': name, **kwargs})
        return {
            'status': 'success',
            'id': record.id,
        }
    except Exception as e:
        return {'status': 'error', 'message': str(e)}
```

## Authentication Methods

| Auth Type | Description |
|-----------|-------------|
| `public` | No login required (uses public user) |
| `user` | Requires a valid session cookie |
| `none` | No Odoo context (manual auth required) |

## API Key Pattern
For external integrations, use a custom API key validation in a `auth='none'` controller.

```python
def _check_api_key(self):
    key = request.httprequest.headers.get('X-API-Key')
    valid_key = request.env['ir.config_parameter'].sudo().get_param('my_module.api_key')
    return key == valid_key

@http.route('/api/secure/data', type='json', auth='none', csrf=False)
def secure_data(self):
    if not self._check_api_key():
        return {'error': 'Unauthorized'}, 401
    return {'data': 'secure content'}
```

## Best Practices
1. **Mimetype**: Odoo handles the `application/json` mimetype automatically for JSON routes.
2. **Error Handling**: Return a dictionary with an `error` or `status` key rather than letting Python exceptions bubble up to the client.
3. **Sudo**: Use `.sudo()` within the controller if the public user needs access to protected models.
4. **CSRF**: JSON routes (`type='json'`) have CSRF protection disabled by default, as they are intended for API use.
