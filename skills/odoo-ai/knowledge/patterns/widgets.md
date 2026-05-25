---
title: Widget Reference
domain: patterns
version: all
edition: both
source: fhidalgo+peterurban+ahmedlakos
status: active
---

# Widget Reference

## Common Widgets Reference

### Text and Selection Widgets
| Widget | Field Types | Description |
|--------|-------------|-------------|
| `char` | Char | Default text input |
| `text` | Text | Multiline textarea |
| `html` | Html | Rich text editor |
| `email` | Char | Email with mailto link |
| `url` | Char | URL with clickable link |
| `phone` | Char | Phone with tel: link |
| `selection` | Selection | Dropdown select |
| `radio` | Selection | Radio buttons |
| `badge` | Selection | Colored badge display |
| `statusbar` | Selection | Status bar progression |

### Numeric Widgets
| Widget | Field Types | Description |
|--------|-------------|-------------|
| `integer` | Integer | Default integer |
| `float` | Float | Default decimal |
| `monetary` | Float/Monetary | Currency formatted |
| `percentage` | Float | Percentage display |
| `progressbar` | Float/Integer | Progress bar |
| `float_time` | Float | Hours:minutes format |
| `handle` | Integer | Drag handle for reordering |

### Relational Widgets
| Widget | Field Types | Description |
|--------|-------------|-------------|
| `many2one` | Many2one | Default dropdown |
| `many2one_avatar` | Many2one | With avatar image |
| `many2one_avatar_user` | Many2one | User with avatar |
| `many2many_tags` | Many2many | Tag pills |
| `many2many_checkboxes` | Many2many | Checkbox list |

---

## Widget Usage in Views

### Form View Widgets
```xml
<form>
    <sheet>
        <group>
            <!-- Text widgets -->
            <field name="name"/>
            <field name="email" widget="email"/>
            <field name="website" widget="url"/>
            <field name="phone" widget="phone"/>
            <field name="description" widget="html"/>

            <!-- Selection widgets -->
            <field name="type" widget="radio"/>
            <field name="priority" widget="priority"/>
            <field name="state" widget="badge"/>

            <!-- Numeric widgets -->
            <field name="amount" widget="monetary"/>
            <field name="discount" widget="percentage"/>
            <field name="progress" widget="progressbar"/>
            <field name="duration" widget="float_time"/>

            <!-- Relational widgets -->
            <field name="user_id" widget="many2one_avatar_user"/>
            <field name="tag_ids" widget="many2many_tags"/>
            <field name="category_ids" widget="many2many_checkboxes"/>

            <!-- Binary widgets -->
            <field name="image" widget="image"/>
            <field name="signature" widget="signature"/>
            <field name="document" widget="binary"/>
        </group>
    </sheet>
</form>
```
