---
title: Common Vulnerabilities
domain: security
version: 18.0
edition: both
source: native
status: complete
priority: P1
---

# Common Odoo Vulnerability Patterns

## Purpose

Use this guide to write and review secure Odoo code. It describes defensive
patterns and safe replacements for common mistakes in custom modules.

## SQL Injection

Never build SQL with string concatenation or interpolation. Always bind values
as parameters.

```python
# Unsafe
self.env.cr.execute("SELECT id FROM res_partner WHERE name = '%s'" % name)

# Safe
self.env.cr.execute(
    "SELECT id FROM res_partner WHERE name = %s",
    (name,),
)
```

Review rule: every `cr.execute()` with user-controlled values must use
parameters. If the SQL contains `%`, `.format()`, or f-strings, stop and rewrite.

## IDOR in Record Access

Do not trust an ID received from a controller, wizard, or client action. Browsing
an arbitrary ID with `sudo()` can expose another user's record.

```python
record = request.env["sale.order"].sudo().browse(order_id)
if record.partner_id != request.env.user.partner_id:
    raise AccessError(_("Access denied."))
```

Review rule: whenever code receives an ID from outside the server-side flow,
verify ownership, company, group, or an explicit access token before operating.

## XSS in QWeb

Use `t-out` for user data. Reserve `t-raw` for trusted HTML produced by the
system and documented at the call site.

```xml
<!-- Unsafe for user content -->
<span t-raw="partner.comment"/>

<!-- Safe default -->
<span t-out="partner.comment"/>
```

Review rule: every `t-raw` must have a clear reason and must not render user
input directly.

## XML Parsing of User Input

Do not parse arbitrary XML from users without validation, limits, and a strict
schema. Prefer Odoo import tools or a controlled data format when possible.

Review rule: any use of `lxml`, `etree`, or XML parsing in controllers/imports
needs input size limits, expected tags, and rejection of unknown structures.

## Mass Assignment

Never pass request payloads directly to `create()` or `write()`. Whitelist fields
that the current user is allowed to change.

```python
allowed = {"phone", "mobile", "street"}
safe_vals = {key: value for key, value in vals.items() if key in allowed}
partner.write(safe_vals)
```

Review rule: controllers and portals must transform request values into
server-approved dictionaries before persistence.

## ir.rule Bypass With sudo()

`sudo()` bypasses record rules. Use it only when the business rule requires it,
and keep the scope as small as possible.

Safe checklist:
- Verify the user can access the business object before `sudo()`.
- Apply `sudo()` to the smallest recordset or helper call.
- Add a short inline comment explaining the rule boundary.

## Exposed Routes

Every route must declare `auth` explicitly and match the data it exposes.

```python
@http.route("/my/orders", type="http", auth="user", website=True)
def portal_orders(self, **kwargs):
    ...
```

Review rule: routes without explicit `auth` or with broad `auth="public"` must
be reviewed for data exposure, ownership checks, and CSRF requirements.
