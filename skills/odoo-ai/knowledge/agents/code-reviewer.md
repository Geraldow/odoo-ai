---
title: Code Reviewer Agent
domain: agents
version: 18.0
edition: both
source: native
status: active
---

# Code Reviewer Agent

The Code Reviewer Agent ensures that Odoo code adheres to the highest standards of quality, security, and performance, specifically following OCA (Odoo Community Association) guidelines and Odoo development best practices.

## 1. OCA Standards & Naming Conventions
- **Naming Models:** Use dot notation (e.g., `hospital.patient`).
- **Naming Fields:** Use snake_case. Many2one fields should end in `_id` (e.g., `partner_id`). Many2many and One2many should end in `_ids`.
- **Naming Methods:** Use descriptive snake_case. Private methods should start with an underscore (e.g., `_compute_total`).
- **File Structure:** Maintain standard Odoo directory structure (`models/`, `views/`, `security/`, `data/`, `static/`, `wizards/`, `report/`).

## 2. Security Checks
- **SQL Injection:** Never use string formatting for SQL queries. Use placeholders:
  ```python
  # Wrong
  self.env.cr.execute("SELECT name FROM res_partner WHERE id = %s" % partner_id)
  # Correct
  self.env.cr.execute("SELECT name FROM res_partner WHERE id = %s", (partner_id,))
  ```
- **Access Rights:** Ensure every model has entries in `ir.model.access.csv`.
- **Record Rules:** Verify that `ir.rule` entries are defined for multi-company or private data scenarios.
- **`sudo()` Usage:** Audit all `sudo()` calls to ensure they don't leak sensitive data.

## 3. ORM Patterns & Performance
- **Avoid Search in Loops:** Never call `search()` or `browse()` inside a loop.
  ```python
  # Wrong
  for partner in partners:
      orders = self.env['sale.order'].search([('partner_id', '=', partner.id)])
  ```
- **Read Group:** Use `read_group()` for aggregations instead of iterating over recordsets.
- **Prefetching:** Leverage Odoo's recordset prefetching by using records together.
- **Computed Fields:** Ensure `store=True` is used only when necessary and that dependencies (`@api.depends`) are correctly defined.

## 4. ACL Coverage
- **Access Logs:** Verify `perm_read`, `perm_write`, `perm_create`, `perm_unlink` are correctly set.
- **Security Groups:** Check that XML views and menuitems are restricted by `groups=""`.
- **Field-level Security:** Check for `groups` attribute on fields in models.

## 5. View Syntax & UX
- **No Inline Styles:** Use CSS classes in `static/src/scss/`.
- **Button Types:** Ensure `type="object"` or `type="action"` is correctly used.
- **Modern Syntax:** For v17+, ensure `invisible`, `readonly`, and `required` attributes use the new boolean or expression syntax instead of `attrs`.

## 6. Logic & Business Rules
- **Method Overrides:** Ensure `super()` is called correctly to maintain the inheritance chain.
- **Error Handling:** Use `odoo.exceptions.UserError` or `ValidationError` for business logic failures.
- **Context Management:** Check if `with_context()` is used appropriately to pass state without modifying the environment globally.

## 7. Testing Coverage
- **Unit Tests:** Ensure business logic is covered by `TransactionCase`.
- **Tour Tests:** Use `HttpCase` for critical frontend flows.
- **Mocking:** Verify that external API calls are properly mocked in tests.
