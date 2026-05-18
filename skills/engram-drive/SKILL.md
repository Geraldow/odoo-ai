---
name: engram-drive
description: >
  Team memory sync via Google Drive. Each person keeps their own engram memories
  in a personal subfolder; teammates' memories are imported automatically.
  Works for any team size, any company, any set of Odoo projects.
  Trigger: /engram-drive [setup|sync|import <project>]
---

## Purpose

Sync engram memories across a development team using Google Drive as a shared
backend — no server required. Each team member exports to their own subfolder
and imports from all teammates. Access control is handled by Google Drive sharing.

## Scripts

All scripts live inside this skill folder:

| Script | Purpose |
|---|---|
| `scripts/detect-environment.ps1` | Scan for Google Drive, Odoo project repos, git contributors |
| `scripts/sync-memories.ps1` | Export your memories + import teammates' memories |

Config lives outside the skill at: `~/.claude/engram-sync-config.json`  
Template: `config-template.json` (copy and fill in before first use)

## Folder Structure in Google Drive

```
<My Drive>/Engram/engram-sync/
├── RULES.md
├── SECURITY.md
├── <project-a>/
│   ├── Alice/       ← Alice's .engram/ lives here (only she writes here)
│   ├── Bob/         ← Bob's .engram/ lives here
│   └── Carol/
└── <project-b>/
    ├── Alice/
    └── Bob/
```

New project = new folder. New teammate = new subfolder. No config change needed.

## Available Commands

```
/engram-drive setup          → interactive onboarding: detect environment, assign roles, create folders
/engram-drive sync           → export your memories + import all teammates (all projects)
/engram-drive sync <project> → sync only one project
/engram-drive import <project> → import only from teammates (no export)
/engram-drive status         → show config summary and Drive folder state
```

---

## /engram-drive setup — Onboarding Flow

Run this once per person, per machine.

### Step 1 — Detect environment

Run the detection script and show results:

```powershell
$skillDir = "$env:USERPROFILE\.claude\skills\engram-drive"
pwsh -NoProfile -File "$skillDir\scripts\detect-environment.ps1" | ConvertFrom-Json
```

Present findings to the user:
- Google Drive: found at `<letter>:\My Drive` — or warn if not found
- Odoo projects detected: list them
- Git contributors per project: list emails + names found

Ask the user to confirm or correct the detected list.

### Step 2 — Collect team information

For each contributor found, ask:

> "Found **{name}** ({email}) in the git history of {projects}. What is their role?"

Show the available roles with a short description for each:

| Role key | Display name | Description |
|---|---|---|
| `tech_lead` | Líder Técnico | Defines architecture, reviews code, makes technical decisions |
| `developer` | Desarrollador | Implements features, writes code, fixes bugs |
| `consultant` | Consultor Funcional | Configures Odoo without code, trains users, maps business processes |
| `analyst` | Analista | Gathers requirements, writes specs, bridges client and team |
| `manager` | Gerente de Proyecto | Manages timelines, resources, client communication |

Also ask: "Which of these is **you** (the person running setup)?" — this sets `owner`.

For the `name` field (subfolder name): default to the person's first name from git.
Ask to confirm: "I'll use **Geraldo** as your folder name — is that correct?"

### Step 3 — Confirm sync base path

Show the detected path: `<Drive>:\My Drive\Engram\engram-sync`

Ask: "Should I use this path, or do you want a different location in your Drive?"

If the user wants to share only certain projects with certain teammates, explain:
> "You control access by sharing individual project subfolders in Google Drive.
> For example, share `engram-sync/omnia/` only with the people who work on omnia."

### Step 4 — Write config and create folders

Write `~/.claude/engram-sync-config.json`:

```json
{
  "owner": "<first name>",
  "base": "<drive letter>:\\My Drive\\Engram\\engram-sync",
  "projects": ["<detected project names>"],
  "team": [
    { "name": "<first name>", "display": "<full name>", "email": "<email>", "role": "<role>" }
  ]
}
```

Then create Drive folder structure for each project + each team member:

```powershell
foreach ($project in $config.projects) {
    foreach ($member in $config.team) {
        $dir = [System.IO.Path]::Combine($config.base, $project, $member.name)
        [System.IO.Directory]::CreateDirectory($dir) | Out-Null
    }
}
```

### Step 5 — First sync and share instructions

Run `scripts/sync-memories.ps1` once to export existing memories to Drive.

Then tell the user:
> "Setup complete. Share the project subfolders with your teammates:
> - Right-click `engram-sync/<project>/` in Google Drive → Share → add teammate email as **Editor**
> - Each teammate runs `/engram-drive setup` on their own machine to configure their side."

---

## /engram-drive sync — Sync Flow

Run `scripts/sync-memories.ps1` via PowerShell:

```powershell
$skillDir = "$env:USERPROFILE\.claude\skills\engram-drive"
pwsh -NoProfile -NonInteractive -File "$skillDir\scripts\sync-memories.ps1"
```

Report a summary line per project:
`✓ aeca — exported 1 chunk | imported: Rachel (3 chunks), Percy (skip — no sync yet)`

## /engram-drive status — Status Flow

Read `~/.claude/engram-sync-config.json` and show:
- Owner name and role
- Base path and whether it exists
- For each project: owner subfolder exists? teammate subfolders found?

## Rules

- Always export BEFORE import (push yours first, then pull teammates)
- Only import from a teammate if their `.engram/manifest.json` exists
- Use `[System.IO.Path]::Combine` and `-LiteralPath` throughout — Drive paths may contain `[brackets]` that PowerShell treats as wildcards
- If Google Drive is not mounted, warn and exit cleanly (do not crash)
- If engram is not in PATH, warn and point to: `claude plugin install engram`
