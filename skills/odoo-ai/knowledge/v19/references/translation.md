---
title: Odoo 19 — Translation Reference
domain: i18n
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Translation Reference

Odoo 19 provides a comprehensive internationalization (i18n) framework to support multi-lingual business operations.

## Python-Side Translations

### The `_()` Wrapper
All user-visible strings in Python must be wrapped in the translation function.

```python
from odoo import _, _lt

class MyModel(models.Model):
    # Standard translation (immediate)
    def action_confirm(self):
        return {
            'warning': {
                'title': _("Warning"),
                'message': _("The record %s is now confirmed.", self.name)
            }
        }

    # Lazy translation (for field strings or defaults)
    description = fields.Text(string=_lt("Description"))
```

### HTML and `Markup`
When including HTML tags in translated strings, use `odoo.tools.Markup` to prevent the framework from escaping the tags in the UI.

```python
from odoo.tools import Markup
from odoo import _

label = Markup(_("<strong>Status:</strong> %s")) % self.state
```

## XML and QWeb Translations

Text within XML tags is automatically extracted for translation.

```xml
<!-- This text will be extracted for .po files -->
<button string="Click Here"/>
<p>Please review the terms and conditions.</p>

<!-- Disable translation for specific blocks -->
<span t-translation="off">Non-translatable technical code</span>
```

## Translation Storage (`.po` files)

Translations are organized in the `i18n/` directory using the Portable Object (`.po`) format.
- `i18n/es.po`: Spanish translations.
- `i18n/fr.po`: French translations.
- `i18n/my_module.pot`: The template file (generated during export).

```po
msgid "The record %s is now confirmed."
msgstr "El registro %s ha sido confirmado."
```

## CLI Tools for i18n

### Exporting Terms
Generate a template (`.pot`) or a language-specific file (`.po`) from the source code.
```bash
# Export all terms to a POT file
python3 odoo-bin -u my_module --i18n-export=my_module.pot
```

### Synchronizing Translations
To refresh the database with updated `.po` files, update the module.
```bash
python3 odoo-bin -u my_module --stop-after-init
```

## Translatable Fields
Individual fields can store different values for each active language.
```python
name = fields.Char("Name", translate=True)
```
In the UI, these fields show a language indicator, allowing users to switch languages and provide specific translations.
