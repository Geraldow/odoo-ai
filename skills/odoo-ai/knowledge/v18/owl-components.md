---
title: Odoo 18 — OWL Components
domain: frontend
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — OWL Components

## Purpose
OWL 2 component patterns, hooks, reactive state, and service injection for Odoo 18.

## Basic Component Structure (v18)
All Odoo 18 frontend code must use the `/** @odoo-module **/` directive and standard ES modules.

```javascript
/** @odoo-module **/
import { Component, useState, onWillStart } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";
import { registry } from "@web/core/registry";

export class MyDashboard extends Component {
    static template = "my_module.MyDashboard";
    static props = {};

    setup() {
        // Services
        this.orm = useService("orm");
        this.action = useService("action");
        this.notification = useService("notification");

        // Reactive State
        this.state = useState({
            records: [],
            loading: true,
        });

        // Lifecycle Hooks
        onWillStart(async () => {
            await this.loadData();
        });
    }

    async loadData() {
        this.state.records = await this.orm.searchRead(
            "res.partner",
            [],
            ["name", "email"]
        );
        this.state.loading = false;
    }

    onNotify() {
        this.notification.add("Data loaded!", { type: "success" });
    }
}

// Register as a Client Action
registry.category("actions").add("my_module.dashboard", MyDashboard);
```

## Template Syntax (XML)
Templates are defined in `static/src/xml/*.xml`.

```xml
<templates xml:space="preserve">
    <t t-name="my_module.MyDashboard">
        <div class="o_dashboard_container p-4">
            <h3>My Dashboard</h3>
            <button class="btn btn-primary mb-3" t-on-click="onNotify">Notify Me</button>
            
            <div t-if="state.loading" class="text-center">
                <i class="fa fa-spinner fa-spin"/> Loading...
            </div>
            
            <ul t-else="">
                <t t-foreach="state.records" t-as="record" t-key="record.id">
                    <li><t t-esc="record.name"/> (<t t-esc="record.email"/>)</li>
                </t>
            </ul>
        </div>
    </t>
</templates>
```

## Component Types and Registries

### Field Widgets
Used for rendering specific fields in form/list views.
```javascript
import { standardFieldProps } from "@web/views/fields/standard_field_props";

export class MyField extends Component {
    static template = "my_module.MyField";
    static props = { ...standardFieldProps };
}
registry.category("fields").add("my_custom_widget", {
    component: MyField,
    supportedTypes: ["char"],
});
```

### Client Actions
Full-page components accessible via menu actions.
```javascript
registry.category("actions").add("my_module.client_action", MyComponent);
```

### Systray Items
Components that appear in the top navbar.
```javascript
export const systrayItem = { Component: MySystrayComponent };
registry.category("systray").add("my_module.systray", systrayItem);
```

## Core Hooks and Services

| Hook / Service | Usage |
|----------------|-------|
| `useState` | Creates a reactive state object. |
| `onWillStart` | Async hook to fetch data before rendering. |
| `useService("orm")` | Standard service to interact with the Python ORM. |
| `useService("action")` | Service to execute window/client actions. |
| `useService("notification")` | Displays toast notifications. |
| `useService("dialog")` | Manages modal windows and confirmations. |

## Asset Registration
Register assets in `__manifest__.py` under the `web.assets_backend` bundle.

```python
'assets': {
    'web.assets_backend': [
        'my_module/static/src/**/*.js',
        'my_module/static/src/**/*.xml',
        'my_module/static/src/**/*.scss',
    ],
},
```

## AI Agent Instructions
When generating Odoo 18.0 OWL components:
1. **Always** include `/** @odoo-module **/` at the top of JS files.
2. **Use** `useState` for any UI reactivity.
3. **Prefer** `onWillStart` for data pre-fetching.
4. **Utilize** standard services (`orm`, `action`, `notification`) instead of manual AJAX.
5. **Ensure** templates use the correct `t-on-` event syntax.
6. **Register** the component in the appropriate `registry.category`.
7. **Define** static `template` and `props` properties in the component class.
