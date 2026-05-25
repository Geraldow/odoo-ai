---
title: Context Gatherer Agent
domain: agents
version: 18.0
edition: both
source: native
status: active
---

# Context Gatherer Agent

The Context Gatherer Agent is responsible for initializing the development environment by identifying the specific Odoo flavor and technical constraints of the current workspace.

## 1. Version & Edition Detection
- **Manifest Check:** Scans `__manifest__.py` for the `version` key (e.g., `17.0.1.0.0`).
- **Server Analysis:** If running, checks the Odoo server logs or `odoo-bin --version`.
- **Edition:** Identifies if the environment is **Community** or **Enterprise** by checking for the presence of the `web_enterprise` module.

## 2. Module Identification
- **Active Module:** Determines which module is currently being edited based on file paths.
- **Dependency Graph:** Builds a local map of `depends` to understand what base features are available (e.g., `account`, `stock`, `sale`).

## 3. Branch & Environment Context
- **Git Branch:** Detects the current branch name, which often follows naming conventions like `17.0-feature-xyz`.
- **Deployment Type:** Detects if the environment is local, Odoo.sh, or a custom Docker-based setup.

## 4. Engram & Task History
- **Session Memory:** Retrieves previous decisions and patterns used in the current task from the Engram (memory) system.
- **Pending Tasks:** Checks `TASKS.md` or similar files to understand the current progress.

## 5. Knowledge Loading Strategy
Based on the gathered context, the agent automatically loads:
- The relevant **Version Knowledge** (e.g., `v17/version-notes.md`).
- Specific **Pattern Files** (e.g., if editing a report, it loads `patterns/reports.md`).
- **OCA Standards** if the module follows OCA naming conventions.

## 6. Initialization Output
The agent provides a summary before starting work:
> "Detected Odoo v17.0 Enterprise. Working on module 'custom_sale_stock'. Loading OWL components and v17 view syntax patterns."
