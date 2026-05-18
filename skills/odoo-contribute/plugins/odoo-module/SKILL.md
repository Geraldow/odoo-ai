---
name: odoo-module
description: >
  Guides creation of Odoo module structure, __manifest__.py fields, __init__.py
  patterns, and module discovery via addons_path.
  Trigger: When creating a new Odoo module, writing __manifest__.py, or structuring
  module folders from scratch.
license: MIT
metadata:
  author: Geraldow
  version: "1.1.0"
  scope: [module]
  auto_invoke:
    - "Creating a new Odoo module from scratch"
    - "Writing or editing __manifest__.py"
    - "Setting up module folder structure"
    - "Configuring auto_install for a bridge module"
    - "Explaining how Odoo discovers modules via addons_path"
---

## When to Use

### Create a new module when

- You are adding functionality that does **not** exist in any installed module
- You need a self-contained feature that can be installed/uninstalled independently
- You are building a bridge between two existing modules (`auto_install`)
- A client requires customizations that must survive Odoo upgrades without patching core

### Do NOT create a new module when

- You only need to add a field or method to an existing model — use `_inherit`
- You are fixing a bug in a standard module — patch via `_inherit`, not a new module
- The feature has no lifecycle independent of an existing module

### Module type decision

```text
Does the feature have a lifecycle independent of existing modules?
├── Yes → New module (installable: True)
│         Is it only useful when two specific modules are both installed?
│         ├── Yes → Bridge module (auto_install: True)
│         └── No  → Regular module (auto_install: False)
│                   Does it appear as a top-level app in the Apps menu?
│                   ├── Yes → Set application: True
│                   └── No  → Leave application: False (default)
└── No  → Inherit the existing module (_inherit)
```

> Before writing any file: know what problem the module solves, what it depends on,
> and whether it is a bridge module. A module without a clear domain is a maintenance burden.

---

## Critical Rules

- ALWAYS set `"installable": True` — without it the module won't appear in Apps
- ALWAYS list `security/ir.model.access.csv` in `data` — omitting it leaves models unprotected
- ALWAYS load `data` files in order: security → views → data → wizards
- NEVER set `auto_install: True` unless this is a bridge/glue module
- NEVER use `application: True` on technical or bridge modules
- NEVER leave `depends` empty if your module uses models from another module
- NEVER skip `__init__.py` in subfolders — Python will not find your classes
- ALWAYS name model files after the model: `sale.order` → `sale_order.py`

---

## `__manifest__.py`

The manifest is the **identity card** of your module. Odoo reads it to decide whether the module can be installed, in what order, and what files to load.

### Required Fields

| Field | Type | Notes |
|-------|------|-------|
| `name` | `str` | The only truly required field. Must be non-empty. |

### Recommended Fields (professional standard)

| Field | Type | Notes |
|-------|------|-------|
| `version` | `str` | Format: `{odoo_major}.0.{major}.{minor}.{patch}` — e.g. `17.0.1.0.0` |
| `summary` | `str` | One line shown under the name in the Apps menu |
| `author` | `str` | Your name or company |
| `license` | `str` | SPDX identifier — `LGPL-3`, `GPL-3`, or `OPL-1` |
| `depends` | `list` | Every module whose models/views you use |
| `data` | `list` | XML/CSV files to load at install, in order |
| `installable` | `bool` | Set `True` to allow installation via UI |

### `depends` vs `auto_install`

**`depends`** declares what your module needs to work. Odoo enforces this: it will refuse to install your module if any listed dependency is missing.

```python
"depends": ["sale_management", "account"],
```

**`auto_install`** makes Odoo install your module automatically when ALL modules in `depends` are already installed. Use only for bridge modules.

```python
# Bridge module: activates automatically when sale + stock are both installed
"depends": ["sale_management", "stock"],
"auto_install": True,
```

### Version Format Convention

```text
{odoo_major}.0.{major}.{minor}.{patch}

17.0.1.0.0   ← first release for Odoo 17
17.0.1.1.0   ← minor feature added
17.0.1.1.1   ← bug fix
18.0.1.0.0   ← same module ported to Odoo 18
```

Always start a new module at `x.0.1.0.0`. Never use `x.0.0.x.x` in production.

---

## `__init__.py` Pattern

`__init__.py` converts a folder into a Python package. Without it, Python cannot import anything from that folder. Think of it as the index of a library wing: it tells Python which files exist and can be imported.

### Root `__init__.py`

```python
# my_module/__init__.py
from . import models
from . import controllers  # only if controllers/ exists
from . import wizard       # only if wizard/ exists
```

### Subpackage `__init__.py`

```python
# my_module/models/__init__.py
from . import sale_order
from . import res_partner
```

> If you create `models/sale_order.py` but forget `from . import sale_order` in `models/__init__.py`,
> Odoo loads the module without errors — but your model class is never registered. Silent failure.

---

## Module Structure

See full annotated tree: [`assets/module_tree.md`](assets/module_tree.md)

### Minimal Viable Structure

```text
my_module/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── my_model.py
└── security/
    └── ir.model.access.csv
```

Add folders only when you have files to put in them — an empty `views/` folder is noise.

### Load Order in `data`

```python
"data": [
    "security/ir.model.access.csv",  # 1. Access rights — always first
    "views/my_model_views.xml",      # 2. Views
    "data/default_data.xml",         # 3. Config/default records
],
```

---

## Module Discovery (`addons_path`)

Odoo only scans directories listed in `addons_path` inside `odoo.conf`:

```ini
[options]
addons_path = /usr/lib/python3/dist-packages/odoo/addons,/opt/my-custom-addons
```

For each path, Odoo looks for subdirectories containing `__manifest__.py`. If the path is not listed, the module is invisible — no error, just silence.

**Module not showing in Apps?** Check in order:
1. Is the folder in `addons_path`?
2. Did you run Settings → Technical → **Update Module List**?
3. Is `"installable": True` in the manifest?
4. Does the manifest have a syntax error? (Python dict, not JSON — no trailing commas)

---

## Common Mistakes

1. **Empty or missing `__init__.py` in a subfolder** — model class never registered, no error thrown.
2. **`ir.model.access.csv` not listed in `data`** — file exists on disk but never loaded; models unprotected.
3. **Wrong version format** — `"1.0.0"` or `"17.1.0.0"` instead of `"17.0.1.0.0"`.
4. **`auto_install: True` on a non-bridge module** — installs on every DB that has the dependency.
5. **Module invisible in Apps** — folder not in `addons_path`, or module list not updated after creation.
6. **[v16→v17] Using `qweb` key in manifest** — removed in v17. Replace with `ir.asset` records in a data XML file bundled via `web.assets_backend` or `web.assets_frontend`.

---

## Assets

| File | When to load |
|------|-------------|
| [`assets/manifest_minimal.py`](assets/manifest_minimal.py) | Starting a new module from scratch |
| [`assets/manifest_full.py`](assets/manifest_full.py) | Need all fields or setting up a bridge module |
| [`assets/module_tree.md`](assets/module_tree.md) | Planning or explaining folder structure |

---

## References

| File | Content |
|------|---------|
| [`references/odoo_docs.md`](references/odoo_docs.md) | Official docs, OCA guidelines, Odoo source pointers |
