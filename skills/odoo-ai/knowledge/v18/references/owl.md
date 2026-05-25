---
title: Odoo 18 — OWL Reference
domain: frontend
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — OWL Reference

Odoo 18 continues to use **OWL 2** as its core frontend framework. OWL (Odoo Web Library) is a declarative component system inspired by Vue and React but optimized for Odoo's specific needs.

## Component Lifecycle Hooks

Lifecycle hooks are methods that allow you to execute code at specific points in a component's life.

| Hook | Description |
|------|-------------|
| `setup` | Called when the component is instantiated. Use it to initialize state and services. |
| `onWillStart` | Asynchronous hook called before the first render. Ideal for loading data. |
| `onMounted` | Called after the component is first attached to the DOM. |
| `onWillRender` | Called before every render (including the first one). |
| `onRendered` | Called after every render (including the first one). |
| `onWillPatch` | Called before the DOM is updated. |
| `onPatched` | Called after the DOM has been updated. |
| `onWillUnmount` | Called before the component is removed from the DOM. |
| `onWillDestroy` | Called before the component is destroyed. |

## Core Hooks

### `useState`
Used to create reactive state. Changes to this state will trigger a re-render.
```javascript
import { useState } from "@odoo/owl";

setup() {
    this.state = useState({ count: 0 });
}
```

### `useRef`
Used to get a reference to a DOM element or a child component marked with `t-ref`.
```javascript
import { useRef } from "@odoo/owl";

setup() {
    this.rootRef = useRef("root");
}
```

### `useService`
Used to access Odoo services (e.g., action, menu, notification, rpc).
```javascript
import { useService } from "@web/core/utils/hooks";

setup() {
    this.actionService = useService("action");
    this.notification = useService("notification");
}
```

## XML Template Syntax

OWL uses a QWeb-inspired XML syntax for its templates.

| Directive | Description | Example |
|-----------|-------------|---------|
| `t-if` | Conditional rendering. | `<div t-if="state.isVisible">...</div>` |
| `t-foreach` | Iteration. | `<li t-foreach="items" t-as="item" t-key="item.id">...</li>` |
| `t-att-*` | Dynamic attributes. | `<div t-att-class="state.active ? 'active' : ''"></div>` |
| `t-on-*` | Event handling. | `<button t-on-click="onClick">Click me</button>` |
| `t-ref` | Reference an element. | `<div t-ref="root"></div>` |
| `t-set` | Define a variable. | `<t t-set="name" t-value="'John'"/>` |
| `t-call` | Call another template. | `<t t-call="MyTemplate"/>` |
| `t-esc` | Escape and output text. | `<span t-esc="value"/>` |
| `t-out` | Output unescaped HTML. | `<div t-out="htmlValue"/>` |

## Event Handling

Events are attached using the `t-on-` directive. The handler receives the native browser event object.

```javascript
// In component
onClick(ev) {
    console.log("Button clicked", ev);
}

// In template
<button t-on-click="onClick">Click Me</button>
```

### Event Bus
Components can communicate via an event bus for decoupled interaction.
```javascript
import { useBus } from "@odoo/owl";
// ...
setup() {
    useBus(this.env.bus, "SOME_EVENT", (ev) => this.handleEvent(ev));
}
```
