---
name: odoo-changelog
description: >
  Manages the CHANGELOG.md for any Odoo project following keepachangelog.com format.
  Trigger: When creating PRs, adding changelog entries, or updating CHANGELOG.md.
license: MIT
model: haiku
metadata:
  author: Geraldow
  version: "2.0.0"
  scope: [root]
  auto_invoke:
    - "Add changelog entry for a PR or feature"
    - "Update CHANGELOG.md"
    - "Create PR that requires changelog entry"
    - "Review changelog format and conventions"
---

## Format Rules (keepachangelog.com)

### Section Order (ALWAYS This Order)

```markdown
## [X.Y.Z] - YYYY-MM-DD

### 🚀 Added
### 🔄 Changed
### ❌ Removed
### 🐞 Fixed
### 🔐 Security
```

### Emoji Prefixes (Required)

| Section  | Emoji            | Usage                                          |
| :------- | :--------------- | :--------------------------------------------- |
| Added    | `### 🚀 Added`    | New modules, features, fields, or views        |
| Changed  | `### 🔄 Changed`  | Modifications to existing behavior or config   |
| Removed  | `### ❌ Removed`  | Deleted features or breaking removals          |
| Fixed    | `### 🐞 Fixed`    | Bug fixes in models, views, or logic           |
| Security | `### 🔐 Security` | Security patches or access rule improvements   |

### Entry Format

```markdown
## [1.1.0] - 2026-03-24

### 🚀 Added

- `action_generate_reference` button on product form for products without reference [(#3)](https://github.com/org/repo/pull/3)
- Category-aware sequence resolution with global fallback [(#3)](https://github.com/org/repo/pull/3)

### 🐞 Fixed

- Prevent collision when concurrent products are created [(#3)](https://github.com/org/repo/pull/3)
```

**Rules:**
- Add new entries at the **bottom** of each section.
- One entry per logical change (can link multiple PRs).
- No period at the end of entries.
- Do NOT use redundant verbs — the section header already conveys the action.
- Link PRs using `[(#NNN)](https://github.com/{org}/{repo}/pull/NNN)`.
- Read the repo remote URL with `git remote get-url origin` to build the correct PR link base.

---

## Odoo Module Versioning Rules

Odoo module versions follow `{odoo}.{major}.{minor}.{patch}` (e.g. `18.0.1.1.0`).

| Change Type                          | What to bump | Example                     |
| :----------------------------------- | :----------- | :-------------------------- |
| Bug fixes, typos, small doc updates  | PATCH        | `18.0.1.0.0` → `18.0.1.0.1` |
| New feature, field, view, or button  | MINOR        | `18.0.1.0.1` → `18.0.1.1.0` |
| Breaking change or major redesign    | MAJOR        | `18.0.1.x.x` → `18.0.2.0.0` |

> **Note:** `### ❌ Removed` entries MUST only appear in MAJOR version releases.

> **odoo.sh**: A version bump in `__manifest__.py` triggers `-u module` on the next deploy. Always bump when DB schema or views change.

---

## Adding an Entry — Step by Step

1. **Check what changed:**
```bash
git diff main...HEAD --name-only
```

2. **Get the repo URL for PR links:**
```bash
git remote get-url origin
```

3. **Determine change type** (Added / Changed / Fixed / Security).

4. **Add entry at the bottom of the correct section** in `CHANGELOG.md`.

5. **Bump version in `__manifest__.py`** if the change affects behavior or DB schema.

---

## Released Versions Are Immutable

**NEVER modify already-released versions.** Once a version is tagged or deployed, that section is frozen.

```markdown
## [1.1.0] - 2026-03-10   ← RELEASED, DO NOT MODIFY

## [1.2.0] - UNRELEASED   ← Add new entries HERE
```

---

## Commands

```bash
# Check what will be in the next release
git log main...HEAD --oneline

# View the current unreleased section
head -40 CHANGELOG.md

# Get remote URL to build PR links
git remote get-url origin
```

---

## Metadata

- **Skill ID**: ODSK-SKL-CHANGELOG
- **Author**: [Geraldow](https://github.com/Geraldow)
- **Repo**: https://github.com/Yven-Labs/odoo-skills
