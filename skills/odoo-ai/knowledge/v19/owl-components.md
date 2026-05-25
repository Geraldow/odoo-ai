---
title: Odoo 19 — OWL Components
domain: frontend
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — OWL Components

## Purpose
OWL component patterns and service injection for Odoo 19. Odoo 19 uses OWL 3.x, which introduces enhanced reactivity, strict prop types, and lifecycle improvements over OWL 2.x.

## OWL 3.x Syntax and Lifecycle

### Component Definition and Prop Types
OWL 3.x enforces stricter typing on props, allowing optional vs required checks directly in the `props` object definition.

```javascript
/** @odoo-module **/

import { Component, useState, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";

export class MyComponent extends Component {
    static template = "my_module.MyComponent";
    
    static props = {
        recordId: { type: Number, required: true },
        onSave: { type: Function, optional: true },
        config: { type: Object, optional: true },
    };
    
    static defaultProps = {
        config: {},
    };

    setup() {
        this.orm = useService("orm");
        this.notification = useService("notification");
        
        this.state = useState({
            data: null,
            loading: true,
            error: null,
        });

        // onWillStart can directly take an async lambda or function returning a promise
        onWillStart(() => this.loadData());
    }

    async loadData() {
        try {
            const [data] = await this.orm.read(
                "my.model",
                [this.props.recordId],
                ["name", "state", "amount"]
            );
            this.state.data = data;
        } catch (error) {
            this.state.error = error.message;
            this.notification.add("Failed to load data", { type: "danger" });
        } finally {
            this.state.loading = false;
        }
    }
}
```

### Key Differences from OWL 2 (v18)
- **Props**: `static props = { field: Type }` is now `static props = { field: { type: Type, required: bool } }`.
- **onWillStart**: Improved error boundaries and async resolution handling. 
- **Reactivity**: More fine-grained tracking in `useState`.
