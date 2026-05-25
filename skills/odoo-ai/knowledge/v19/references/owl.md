---
title: Odoo 19 — OWL Reference
domain: frontend
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — OWL Reference

Odoo 19 continues to leverage **OWL 2** as its core frontend framework, further refining the component system for better performance and developer experience. OWL (Odoo Web Library) remains a declarative component system optimized for Odoo's unique requirements.

## Component Lifecycle Hooks

Lifecycle hooks allow developers to execute logic at specific stages of a component's lifecycle.

| Hook | Description |
|------|-------------|
| `setup` | Called during component instantiation. Primary place for state and service initialization. |
| `onWillStart` | Asynchronous hook called before the first render. Used for pre-loading data. |
| `onMounted` | Called after the component is attached to the DOM. |
| `onWillRender` | Called before every render cycle. |
| `onRendered` | Called after every render cycle. |
| `onWillPatch` | Called before the DOM is updated due to state changes. |
| `onPatched` | Called after the DOM has been updated. |
| `onWillUnmount` | Called before the component is detached from the DOM. |
| `onWillDestroy` | Called before the component is fully destroyed. |

## Core Hooks

### `useState`
Creates reactive state objects. Changes to properties within these objects automatically trigger re-renders.
```javascript
import { useState } from "@odoo/owl";

setup() {
    this.state = useState({ count: 0, status: 'idle' });
}
```

### `useRef`
Provides a reference to a DOM element or a child component tagged with `t-ref`.
```javascript
import { useRef } from "@odoo/owl";

setup() {
    this.rootRef = useRef("root");
}
```

### `useService`
The standard way to interact with Odoo's global services (e.g., `action`, `menu`, `notification`, `rpc`).
```javascript
import { useService } from "@web/core/utils/hooks";

setup() {
    this.actionService = useService("action");
    this.notification = useService("notification");
}
```

## XML Template Syntax (QWeb)

OWL templates use a modern version of QWeb syntax for declarative UI.

| Directive | Description | Example |
|-----------|-------------|---------|
| `t-if` | Conditional rendering logic. | `<div t-if="state.isVisible">...</div>` |
| `t-foreach` | List iteration. Requires a unique `t-key`. | `<li t-foreach="items" t-as="item" t-key="item.id">...</li>` |
| `t-att-*` | Dynamic attribute binding. | `<div t-att-class="state.active ? 'active' : ''"></div>` |
| `t-on-*` | Event listener binding. | `<button t-on-click="onClick">Click me</button>` |
| `t-ref` | Marks an element for `useRef`. | `<div t-ref="root"></div>` |
| `t-set` | Declares a template variable. | `<t t-set="name" t-value="'John'"/>` |
| `t-call` | Invokes a sub-template. | `<t t-call="MyTemplate"/>` |
| `t-esc` | Safely outputs escaped text. | `<span t-esc="value"/>` |
| `t-out` | Outputs unescaped HTML content. | `<div t-out="htmlValue"/>` |

## Event Handling

Events are handled via the `t-on-` directive. The handler receives the standard browser Event object.

```javascript
// Component Logic
onClick(ev) {
    console.log("Button clicked", ev);
}

// Template
<button t-on-click="onClick">Click Me</button>
```

### Global Bus Communication
Components can communicate across hierarchies using the environment bus.
```javascript
import { useBus } from "@odoo/owl";

setup() {
    useBus(this.env.bus, "RELOAD_DATA", (ev) => this.handleReload(ev));
}
```
