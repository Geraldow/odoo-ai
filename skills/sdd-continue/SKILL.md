---
model: sonnet
description: Create the next missing artifact in the SDD dependency chain for a change. Use as /sdd-continue [change-name].
---

# /sdd-continue — Continue SDD Change

This is a **meta-command** that identifies the next missing artifact in the dependency chain and creates it.

## Dependency Graph

```
proposal → specs ──→ tasks → apply → verify → archive
             ↑
           design
```

## Step 1: Identify Active Change

- If change name provided: use it directly
- If NOT provided:
  - **engram**: `mem_search("sdd/*/state")` to find active changes
  - **openspec**: List directories in `openspec/changes/` (excluding `archive/`)
  - Present the list and ask user which change to continue
  - **STOP and wait for user response**

## Step 2: Check Current State

Retrieve DAG state:
- **engram**: `mem_search("sdd/{change-name}/state")` → `mem_get_observation(id)` → parse YAML
- **openspec**: Read `openspec/changes/{change-name}/state.yaml`
- **none**: Check what artifacts exist in conversation context

Determine which artifacts exist:

| Artifact                    | Exists? |
| --------------------------- | ------- |
| proposal                    | ☐       |
| specs                       | ☐       |
| design                      | ☐       |
| tasks                       | ☐       |
| apply (all tasks complete?) | ☐       |
| verify-report               | ☐       |
| archive                     | ☐       |

## Step 3: Determine Next Phase

Based on the dependency graph:

| If missing...      | Then run...    | Requires...                           |
| ------------------ | -------------- | ------------------------------------- |
| proposal           | `/sdd-propose` | nothing (or exploration)              |
| specs              | `/sdd-spec`    | proposal                              |
| design             | `/sdd-design`  | proposal (spec optional)              |
| tasks              | `/sdd-tasks`   | proposal + specs + design             |
| apply (incomplete) | `/sdd-apply`   | tasks                                 |
| verify-report      | `/sdd-verify`  | all tasks complete                    |
| archive            | `/sdd-archive` | verify-report with no CRITICAL issues |

If a required dependency is missing, create it first.

## Step 4: Execute the Next Phase

Run the identified workflow following ALL its steps as documented in the corresponding `/sdd-*` workflow.

## Step 5: Update State

After successful completion:
- **engram**: `mem_save(title: "sdd/{change-name}/state", topic_key: "sdd/{change-name}/state", ...)`
- **openspec**: Update `openspec/changes/{change-name}/state.yaml`

## Step 6: Return Progress

```markdown
## SDD Progress

**Change**: {change-name}
**Phase completed**: {what was just done}
**Artifacts**: {what was produced}
**Next recommended**: {what to do next}
```

## Rules

- ALWAYS check the dependency graph before running a phase
- If a required dependency is missing, create it first (or inform the user)
- NEVER skip phases — follow the dependency chain
- If change name is ambiguous or missing, ALWAYS ask the user
