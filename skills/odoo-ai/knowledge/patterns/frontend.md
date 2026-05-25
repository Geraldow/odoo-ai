---
title: Frontend & Theme Patterns
domain: patterns
version: all
edition: both
source: fhidalgo+peterurban+ahmedlakos
status: active
---

# Frontend & Theme Patterns

## Basic OWL Component Structure (v18)

```javascript
/** @odoo-module **/

import { Component, useState, useRef, onWillStart, onMounted } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";
import { registry } from "@web/core/registry";

export class MyComponent extends Component {
    static template = "my_module.MyComponent";
    static props = {
        recordId: { type: Number, optional: true },
        mode: { type: String, optional: true },
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

// Register as client action
registry.category("actions").add("my_module.my_component", MyComponent);
```

## Template Structure (XML)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<templates xml:space="preserve">
    <t t-name="my_module.MyComponent">
        <div class="o_my_component">
            <t t-if="state.loading">
                <span>Loading...</span>
            </t>
            <t t-else="">
                <div class="o_header">
                    <h2>My Component</h2>
                </div>
                <div class="o_content">
                    <t t-foreach="state.data" t-as="item" t-key="item.id">
                        <div class="item">
                            <t t-esc="item.name"/>
                        </div>
                    </t>
                </div>
            </t>
        </div>
    </t>
</templates>
```
