# ODSK-SKL-MODULE | Asset: module_tree.md

Annotated directory tree for an Odoo module.

**Legend:**
- `[R]` Required — module won't load without this
- `[S]` Standard — expected in almost every module
- `[O]` Optional — include only when the feature exists

---

## Minimal Viable Module

```text
my_module/
├── __init__.py              [R] Makes this folder a Python package.
│                                Content: `from . import models`
├── __manifest__.py          [R] Declares the module to Odoo.
│
└── models/
    ├── __init__.py          [R] Makes models/ a Python package.
    │                            Content: `from . import my_model`
    └── my_model.py          [S] Your first model class.
```

---

## Full Module Structure

```text
my_module/
├── __init__.py              [R] from . import models, controllers, wizard
├── __manifest__.py          [R]
│
├── models/                  [R] Business logic — fields, methods, constraints.
│   ├── __init__.py
│   ├── my_model.py
│   └── res_partner.py           Inherited models use the original model name.
│
├── views/                   [S] XML views: form, list, kanban, search, menus.
│   ├── my_model_views.xml
│   └── menus.xml
│
├── security/                [S] Access control — always include this.
│   ├── ir.model.access.csv      One line per model per group.
│   └── security.xml             Groups and record rules (if needed).
│
├── data/                    [O] Default/config records loaded at install.
│   └── default_data.xml
│
├── demo/                    [O] Demo records for dev/runbot databases only.
│   └── demo_data.xml
│
├── controllers/             [O] HTTP routes and JSON-RPC endpoints.
│   ├── __init__.py
│   └── main.py
│
├── wizard/                  [O] TransientModel dialogs (one-time actions).
│   ├── __init__.py
│   └── my_wizard.py
│
├── report/                  [O] QWeb PDF/HTML reports.
│   ├── report_my_doc.xml        Template definition.
│   └── report_my_doc_action.xml Report action (ir.actions.report).
│
├── static/                  [O] Frontend assets — JS, CSS, images, icons.
│   ├── description/
│   │   └── icon.png             Shown in Apps menu (128x128 PNG).
│   └── src/
│       ├── js/
│       └── css/
│
└── tests/                   [S] Always include tests. Always.
    ├── __init__.py
    └── test_my_model.py
```

---

## Key Rules

1. Every folder with `.py` files MUST have an `__init__.py`.
2. Every file in `models/`, `controllers/`, `wizard/` MUST be imported in its `__init__.py`.
3. List `data/`, `demo/` files in `__manifest__.py` in load order (security first).
4. Never put business logic in `views/` — only XML.
5. One model class per file. Name the file after the model: `sale_order.py` → `SaleOrder`.
