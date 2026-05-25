---
title: Skill Finder Agent
domain: agents
version: 18.0
edition: both
source: native
status: active
---

# Skill Finder Agent

The Skill Finder Agent acts as a router, mapping user requirements to the most relevant technical patterns and knowledge files within the Odoo AI ecosystem.

## 1. Keyword Mapping Table

| User Task / Keyword | Recommended Knowledge Path |
| :--- | :--- |
| "new model", "field", "onchange" | `patterns/orm-patterns.md` |
| "xml", "form view", "xpath" | `patterns/xml-views.md` |
| "access rights", "groups", "rules" | `security/access-rules.md` |
| "button", "server action", "wizard" | `patterns/wizards.md` |
| "owl", "javascript", "component" | `v18/owl-components.md` |
| "migrate", "breaking change" | `agents/upgrade-analyzer.md` |
| "test", "unittest", "tour" | `testing/patterns.md` |
| "report", "pdf", "qweb" | `patterns/reports.md` |

## 2. Decision Tree for Pattern Selection

1. **Is it a Backend Change?**
   - Yes -> Is it Data Structure? -> `orm-patterns.md`
   - Yes -> Is it UI/UX? -> `xml-views.md`
   - Yes -> Is it Logic/Process? -> `wizards.md` or `actions.md`
2. **Is it a Frontend Change?**
   - Yes -> Is it a new Widget/Component? -> `owl-components.md`
   - Yes -> Is it Styling? -> `visual.md`
3. **Is it a Maintenance Task?**
   - Yes -> Is it Security? -> `security/`
   - Yes -> Is it Performance? -> `core/performance.md`
   - Yes -> Is it Version Upgrade? -> `migration/`

## 3. Routing Logic
The agent doesn't just find a file; it identifies the **Mode of Operation**:
- **Discovery Mode:** Used when the user asks "How do I...". Routes to templates and patterns.
- **Fix Mode:** Used when a bug is reported. Routes to debugging patterns and security checklists.
- **Refactor Mode:** Used when code is provided for review. Routes to `agents/code-reviewer.md`.

## 4. Entry Point (SKILL.md)
The agent ensures that the main `SKILL.md` is updated with pointers to new knowledge files as they are authored, maintaining a single source of truth for navigation.
