---
title: Odoo 18 — Translation Reference
domain: i18n
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Translation Reference

Odoo provides a robust internationalization (i18n) system to support multi-language environments.

## Python Translations

### The `_()` Function
Wrap user-facing strings in `_()` to make them translatable.

```python
from odoo import _

def my_method(self):
    raise UserError(_("The record %s is not valid.", self.name))
```

### `Markup` and Safety
When combining translations with HTML, use `odoo.tools.Markup`.

```python
from odoo.tools import Markup
from odoo import _

msg = _("Hello <b>%s</b>") % self.name
# Use Markup to ensure the <b> tag is not escaped when rendered
safe_msg = Markup(msg)
```

## QWeb Translations

In XML views and reports, text inside tags is automatically extracted for translation. Use `t-translation="off"` to disable this for specific blocks.

```xml
<span>This text will be translated</span>
<span t-translation="off">This will NOT</span>
```

For attributes:
```xml
<input placeholder="Search..."/> <!-- placeholder is translatable -->
```

## .po File Structure

Translations are stored in `.po` files inside the `i18n/` directory of a module (e.g., `es.po`, `fr.po`).

```po
#. module: my_module
#: code:addons/my_module/models/my_model.py:0
#, python-format
msgid "The record %s is not valid."
msgstr "El registro %s no es válido."
```

## i18n Commands

### Exporting Terms
Generate a `.pot` template containing all translatable strings in a module.
```bash
python3 odoo-bin -u my_module --i18n-export=my_module.pot
```

### Importing/Updating
To load new translations after editing a `.po` file, update the module:
```bash
python3 odoo-bin -u my_module
```

## Multi-language Fields
Fields can be marked as translatable in the model definition.
```python
name = fields.Char("Name", translate=True)
```
This allows storing different values for the same field depending on the user's language.
