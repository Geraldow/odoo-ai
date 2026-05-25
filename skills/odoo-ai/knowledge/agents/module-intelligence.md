---
title: Module Intelligence Agent
domain: agents
version: 18.0
edition: both
source: native
status: active
---

# Module Intelligence Agent

The Module Intelligence Agent provides a systematic approach to analyzing and understanding any Odoo module. It follows a 10-step process to map the module's architecture and functionality.

## 10-Step Analysis Process

### Step 1: Manifest Analysis (`__manifest__.py`)
Identify the module's purpose, version, category, and critical dependencies. Check the `data` and `assets` keys to understand the resource loading order.

### Step 2: Models & Fields (`models/*.py`)
Map the data structure. Identify new models and extensions of existing ones (`_inherit`). Look for key fields, computed logic, and constraints.

### Step 3: Views & Actions (`views/*.xml`)
Analyze the User Interface. Look for `ir.ui.view` definitions, `ir.actions.act_window` for navigation, and `menuitem` hierarchies. Identify XPath extensions of base views.

### Step 4: Security (`security/*`)
Verify `ir.model.access.csv` for base permissions and `ir.rule` for record-level security. Check `res.groups` definitions that control feature access.

### Step 5: Controllers & Routes (`controllers/*.py`)
Identify any web-facing APIs or website integrations. Map the routes (`@http.route`) and their authentication methods (`auth="user"`, `"public"`, or `"none"`).

### Step 6: OWL Components (`static/src/components/*`)
For modern Odoo (v14+), analyze the frontend architecture. Identify OWL components, templates (`xml` files in `static`), and JS classes extending the web client.

### Step 7: Automated Tests (`tests/*.py`)
Review existing tests to understand the expected behavior and edge cases. Check for `TransactionCase` (backend) and `HttpCase` (frontend/tours).

### Step 8: Dependencies
Examine external Python dependencies (`requirements.txt`) and other Odoo modules needed. Understand the "bridge" modules if this module connects two large apps.

### Step 9: Hooks (`__init__.py`)
Check for `pre_init_hook`, `post_init_hook`, or `uninstall_hook`. These often contain critical data migration or configuration logic that doesn't run during normal updates.

### Step 10: Data Files (`data/*.xml`, `data/*.csv`)
Identify bootstrap data, sequences, cron jobs, and mail templates. These define the initial state and automated background behavior of the module.

## Mode 1: Module Intelligence
Deep dive into a specific module's internals using the 10 steps above to provide a comprehensive architectural report.

## Mode 2: Pattern Search (Enterprise First)
Analyzes how Odoo Enterprise implements similar features to ensure custom development aligns with the "Odoo Way" and maximizes reuse of existing frameworks.

## Mode 3: Migration Pattern Search
Identifies legacy patterns in a module (e.g., v14 style) and maps them to the target version's modern equivalents (e.g., v18 OWL or API changes).
