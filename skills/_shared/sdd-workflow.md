# SDD Workflow — Sub-Agent Reference

Read this file when launching sub-agents for SDD phases or general delegation tasks.

---

## Sub-Agent Launch Pattern

Include a SKILL LOADING section in the sub-agent prompt (between TASK and PERSISTENCE):

```text
SKILL LOADING (do this FIRST):
Check for available skills:
  1. Try: mem_search(query: "skill-registry", project: "{project}")
  2. Fallback: read .atl/skill-registry.md
Load and follow any skills relevant to your task.
```

---

## Sub-Agent Context Protocol

Sub-agents get a fresh context with NO memory. The orchestrator controls context access.

### Non-SDD Tasks (general delegation)

- **Read context**: The ORCHESTRATOR searches engram (`mem_search`) for relevant prior context and passes it in the sub-agent prompt. The sub-agent does NOT search engram itself.
- **Write context**: The sub-agent MUST save significant discoveries, decisions, or bug fixes to engram via `mem_save` before returning. It has the full detail — if it waits for the orchestrator, nuance is lost.
- **When to include engram write instructions**: Always. Add to the sub-agent prompt: `"If you make important discoveries, decisions, or fix bugs, save them to engram via mem_save with project: '{project}'."`

### SDD Phases

Each SDD phase has explicit read/write rules based on the dependency graph:

| Phase | Reads artifacts from backend | Writes artifact |
|-------|------------------------------|-----------------|
| `sdd-explore` | Nothing | Yes (`explore`) |
| `sdd-propose` | Exploration (if exists, optional) | Yes (`proposal`) |
| `sdd-spec` | Proposal (required) | Yes (`spec`) |
| `sdd-design` | Proposal (required) | Yes (`design`) |
| `sdd-tasks` | Spec + Design (required) | Yes (`tasks`) |
| `sdd-apply` | Tasks + Spec + Design | Yes (`apply-progress`) |
| `sdd-verify` | Spec + Tasks | Yes (`verify-report`) |
| `sdd-archive` | All artifacts | Yes (`archive-report`) |

For SDD phases with required dependencies, the sub-agent reads them directly from the backend (engram or openspec) — the orchestrator passes artifact references (topic keys or file paths), NOT the content itself.

### Engram Topic Key Format

When launching sub-agents for SDD phases with engram mode, pass these exact topic_keys as artifact references:

| Artifact | Topic Key |
|----------|-----------|
| Project context | `sdd-init/{project}` |
| Exploration | `sdd/{change-name}/explore` |
| Proposal | `sdd/{change-name}/proposal` |
| Spec | `sdd/{change-name}/spec` |
| Design | `sdd/{change-name}/design` |
| Tasks | `sdd/{change-name}/tasks` |
| Apply progress | `sdd/{change-name}/apply-progress` |
| Verify report | `sdd/{change-name}/verify-report` |
| Archive report | `sdd/{change-name}/archive-report` |
| DAG state | `sdd/{change-name}/state` |

Sub-agents retrieve full content via two steps:
1. `mem_search(query: "{topic_key}", project: "{project}")` → get observation ID
2. `mem_get_observation(id: {id})` → full content (REQUIRED — search results are truncated)

---

## State and Conventions (source of truth)

Shared convention files under `skills/_shared/` (resolved from the active platform's skills install path):
- `engram-convention.md` — artifact naming and two-step recovery
- `persistence-contract.md` — mode behavior and state persistence/recovery
- `openspec-convention.md` — file layout when mode is `openspec`

> Each platform installs skills to its own path (`~/.gemini/skills/`, `~/.claude/skills/`, `~/.config/opencode/skills/`, `~/.codex/skills/`). The `skills/_shared/` path is always relative to the active platform's skills root.
