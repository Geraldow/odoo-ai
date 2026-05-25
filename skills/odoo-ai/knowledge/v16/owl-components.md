---
title: Odoo 16 — OWL Components
domain: frontend
version: 16.0
edition: community
source: legacy
status: active
---

# Odoo 16 — OWL Components

## Purpose
OWL 2 component patterns, hooks, and service injection for Odoo 16.

## Basic Component Structure (OWL 2.x)

```javascript
/** @odoo-module **/

import { Component, useState, useRef, onWillStart, onMounted } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";
import { registry } from "@web/core/registry";

export class MyComponent extends Component {
    static template = "my_module.MyComponent";
    static props = {
        recordId: { type: Number, optional: true },
    };

    setup() {
        // Services
        this.orm = useService("orm");
        this.action = useService("action");
        this.notification = useService("notification");

        // State
        this.state = useState({
            data: [],
            loading: true,
        });

        // Lifecycle
        onWillStart(async () => {
            await this.loadData();
        });
    }

    async loadData() {
        this.state.data = await this.orm.searchRead(
            "my.model",
            [],
            ["name", "state"]
        );
        this.state.loading = false;
    }
}

registry.category("actions").add("my_module.my_action", MyComponent);
```

## Template Structure (OWL 2.x)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<templates xml:space="preserve">
    <t t-name="my_module.MyComponent">
        <div class="o_my_component">
            <t t-if="state.loading">
                <i class="fa fa-spinner fa-spin"/> Loading...
            </t>
            <t t-else="">
                <table class="table">
                    <t t-foreach="state.data" t-as="item" t-key="item.id">
                        <tr>
                            <td t-esc="item.name"/>
                        </tr>
                    </t>
                </table>
            </t>
        </div>
    </t>
</templates>
```

## ORM Service Usage

```javascript
const orm = useService("orm");

// Search and read
const records = await orm.searchRead("res.partner", [["is_company", "=", true]], ["name"]);

// Call method
const result = await orm.call("res.partner", "custom_method", [[id]]);
```

## v16 OWL 2.x Checklist

- [ ] Use `/** @odoo-module **/` directive.
- [ ] Import from `@odoo/owl` directly.
- [ ] Use `useService()` for orm, action, notification.
- [ ] Use `registry.category().add()` for registration.
- [ ] Define `static template` and `static props`.
- [ ] Do NOT use `odoo.define()` or `require()`.

## Best Practices for v17 Compatibility

- **Add JSDoc type annotations**.
- **Use props validation** with `validate` functions.
- **Implement proper cleanup** in `onWillUnmount`.
