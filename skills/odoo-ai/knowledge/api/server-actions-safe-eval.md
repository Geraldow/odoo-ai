---
title: Server Actions and safe_eval
domain: api
version: 18.0
edition: both
source: native
status: active
---

# Server Actions and safe_eval

## Overview
Server actions (`ir.actions.server`) allow for the execution of complex logic triggered by the user interface, automated actions, or scheduled cron jobs. They provide a powerful way to extend Odoo's behavior without necessarily writing a new controller or complex view logic.

## Action Types
Server actions can perform several types of operations:
- **Execute Python Code:** The most flexible type, allowing any valid Odoo Python code.
- **Create a New Record:** Simplifies record creation in a specific model.
- **Update the Record:** Modifies fields on the current record or related records.
- **Execute several actions:** Chains multiple server actions together.
- **Send Email:** Triggers an email template.
- **Add Followers:** Automatically adds partners to a record's chatter.

## safe_eval Context
When executing Python code in a server action, Odoo uses `tools.safe_eval` to ensure that the code runs in a controlled environment. This prevents the execution of malicious or dangerous operations (like `import os` or `eval()`).

The default context available in a server action includes:
- `env`: The Odoo environment (e.g., `env['res.partner']`).
- `model`: The model object on which the action is triggered.
- `record`: The current record (for single record actions).
- `records`: A recordset of all selected records (for multi-record actions).
- `datetime`, `dateutil`, `time`: Useful libraries for time manipulation.
- `user`: The current user record.
- `log`: A function to log messages in the server logs.

### Example: Execute Python Code
```python
# Update the description of selected records
for rec in records:
    rec.write({
        'description': f"Processed on {datetime.datetime.now()}"
    })
```

## ir.actions.server Definition
In XML, a server action is defined as follows:

```xml
<record id="action_mark_as_done" model="ir.actions.server">
    <field name="name">Mark as Done</field>
    <field name="model_id" ref="model_my_custom_model"/>
    <field name="binding_model_id" ref="model_my_custom_model"/>
    <field name="binding_view_types">list,form</field>
    <field name="state">code</field>
    <field name="code">
        records.write({'state': 'done'})
    </field>
</record>
```

### Security Considerations
- **Validation:** Always validate input and state before performing operations.
- **Performance:** Avoid heavy loops or complex queries in actions that might be triggered on many records simultaneously. Use recordset operations whenever possible.
- **Access Rights:** Server actions respect the access rights of the user executing them, unless explicitly bypassed using `sudo()`.
