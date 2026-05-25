---
title: Plugin Trigger Debugging
domain: debugging
version: 18.0
edition: both
source: native
status: active
---

# Plugin Trigger Debugging

## Debug Mode Detection
Check if the server is running in debug mode to enable verbose logging for triggers and hooks.

```python
from odoo.tools import config

def is_debug_mode():
    """Check if server is in debug or dev mode."""
    return config.get('dev_mode') or config.get('debug')

class MyTrigger(models.Model):
    _inherit = 'res.partner'

    def write(self, vals):
        if is_debug_mode():
            _logger.debug("Triggering partner update hook for %s with vals %s", self.id, vals)
        return super().write(vals)
```

## Request Tracing
For triggers initiated via HTTP (controllers or webhooks), use a request ID to trace the execution flow.

```python
import uuid
from odoo import http

class WebhookController(http.Controller):
    @http.route('/webhook/trigger', type='json', auth='none')
    def handle_trigger(self, **kwargs):
        req_id = str(uuid.uuid4())[:8]
        _logger.info("[%s] Incoming trigger request: %s", req_id, kwargs)
        
        try:
            # logic here
            _logger.info("[%s] Trigger successfully processed", req_id)
        except Exception as e:
            _logger.error("[%s] Trigger failed: %s", req_id, e)
```

## Temporary Debug Output
When a hook isn't triggering, use a dedicated debug helper to inspect the record state immediately before the trigger point.

```python
def debug_trigger_state(self):
    """Log record details for trigger troubleshooting."""
    self.ensure_one()
    _logger.info("=== TRIGGER DEBUG: %s ===", self._name)
    _logger.info("  ID: %s", self.id)
    _logger.info("  State: %s", self.state)
    _logger.info("  Context: %s", self.env.context)
    _logger.info("============================")
```

## Common Trigger Issues
1. **Sudo Context**: Hooks running in `sudo()` might bypass certain security-based triggers.
2. **Transaction Rollback**: If an exception occurs later in the same transaction, the trigger's side effects (like logs in DB) will be rolled back.
3. **Registry Out of Sync**: New triggers added to models might require a server restart or module update to be registered.
