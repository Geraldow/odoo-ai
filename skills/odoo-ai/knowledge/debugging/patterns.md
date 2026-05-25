---
title: Debugging Patterns
domain: debugging
version: 18.0
edition: both
source: native
status: active
---

# Debugging Patterns

## Logging Setup

### Module Logger
Always use a module-specific logger to allow fine-grained control over log levels.

```python
import logging

_logger = logging.getLogger(__name__)

class MyModel(models.Model):
    _name = 'my.model'

    def process_record(self):
        _logger.info("Processing record %s", self.id)
        try:
            result = self._do_work()
            _logger.debug("Work completed: %s", result)
            return result
        except Exception as e:
            _logger.error("Failed to process record %s: %s", self.id, e)
            _logger.exception("Full traceback:")
            raise
```

### Log Levels
| Level | Use Case |
|-------|----------|
| `DEBUG` | Detailed diagnostic info (disabled in production) |
| `INFO` | Normal operation events |
| `WARNING` | Unexpected but non-breaking events |
| `ERROR` | Operation-impacting errors |
| `CRITICAL` | System-level failures |

## Performance Logging

### Query Profiling
Use a context manager to track slow operations.

```python
import time

class PerformanceLogger:
    def __init__(self, operation_name):
        self.operation_name = operation_name
        self.start_time = None

    def __enter__(self):
        self.start_time = time.time()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        if duration > 1.0:
            _logger.warning("Slow operation: %s took %.2fs", self.operation_name, duration)

# Usage
def compute_report(self):
    with PerformanceLogger("compute_report"):
        # Heavy computation
        pass
```

## Audit Logging Mixin
A common pattern for tracking sensitive changes.

```python
class AuditMixin(models.AbstractModel):
    _name = 'audit.mixin'

    def write(self, vals):
        for record in self:
            _logger.info("AUDIT: User %s updated %s record %s: %s", 
                        self.env.user.login, self._name, record.id, vals)
        return super().write(vals)

    @api.model_create_multi
    def create(self, vals_list):
        records = super().create(vals_list)
        for record in records:
             _logger.info("AUDIT: User %s created %s record %s", 
                         self.env.user.login, self._name, record.id)
        return records
```

## Best Practices
1. **Lazy Formatting**: Use `_logger.info("x=%s", x)` instead of f-strings to avoid computation if the log level is disabled.
2. **Tracebacks**: Use `_logger.exception()` in except blocks to capture the full stack trace.
3. **No Sensitive Data**: Never log passwords, tokens, or PII.
4. **Context**: Include record IDs and user information in logs for better traceability.
