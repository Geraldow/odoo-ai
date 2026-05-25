---
title: Odoo 17 — OWL Components
domain: frontend
version: 17.0
edition: community
source: legacy
status: active
---

# Odoo 17 — OWL Components (OWL 2.x)

## Basic Component Structure

```javascript
/** @odoo-module **/

import { Component, useState, onWillStart, onMounted } from "@odoo/owl";
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
        this.notification = useService("notification");
        this.action = useService("action");

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
        try {
            this.state.data = await this.orm.searchRead(
                "my.model",
                [],
                ["name", "state"]
            );
        } finally {
            this.state.loading = false;
        }
    }
}

registry.category("actions").add("my_module.my_action", MyComponent);
```

## Template Example

```xml
<templates xml:space="preserve">
    <t t-name="my_module.MyComponent">
        <div class="o_my_component p-3">
            <t t-if="state.loading">
                <span>Loading...</span>
            </t>
            <t t-else="">
                <t t-foreach="state.data" t-as="item" t-key="item.id">
                    <div class="item">
                        <strong t-esc="item.name"/>
                    </div>
                </t>
            </t>
        </div>
    </t>
</templates>
```

## Services Reference

| Service | Usage |
|---------|-------|
| `orm` | Database operations |
| `action` | Execute actions (act_window, etc.) |
| `notification` | Display toast notifications |
| `dialog` | Open modal dialogs |
| `user` | Current user information |
| `company` | (v18+) Current company information |

## v17 Checklist

- [ ] Use `/** @odoo-module **/` directive
- [ ] Import from `@odoo/owl`
- [ ] Use `useService()` for all services
- [ ] Define `static props` for validation
- [ ] Use `registry.category().add()` for registration
- [ ] Include in manifest assets

## Best Practices

### JSDoc Type Annotations
```javascript
/** @type {import("@web/core/orm_service").ORM} */
this.orm = useService("orm");
```

### Static Props Validation
```javascript
static props = {
    recordId: { type: Number },
    mode: { type: String, optional: true },
};
```
