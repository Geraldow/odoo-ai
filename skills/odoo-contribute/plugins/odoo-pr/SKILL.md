---
name: odoo-pr
description: >
  Creates Pull Requests for any Odoo project following Odoo module conventions.
  Trigger: When creating PRs, reviewing PR requirements, or checking PR title conventions.
license: MIT
model: sonnet
metadata:
  author: Geraldow
  version: "1.2.0"
  scope: [root]
  auto_invoke:
    - "Create a PR with gh pr create"
    - "Review PR requirements and template"
    - "Fill pull request sections for an Odoo module"
---

## PR Creation Process

1. **Detect context**: Read `__manifest__.py` to get module name, version, and license.
2. **Detect edition**: `LGPL-3` / `AGPL-3` = Community. `OEEL-1` = Enterprise.
3. **Detect Odoo version**: Read major version from `__manifest__.py` (e.g. `18.0.1.0.0` → v18). Default: v18 per CLAUDE.md.
4. **Analyze changes**: `git diff main...HEAD` to understand ALL commits.
5. **Fill template** based on changes.
6. **Create PR** with `gh pr create`.

---

## PR Template Structure

```markdown
### Context

{Why this change? Describe the business or technical reason. Link issues with `Fix #XXXX` if applicable.}

### Description

{Summary of changes. Mention which Odoo module and version are affected.}

- **Module**: {module technical name, e.g. `product_auto_reference`}
- **Odoo Version**: {vXX — read from __manifest__.py}
- **Edition**: {Community / Enterprise — read from license field}
- **Breaking Change**: {Yes/No — does this modify existing behavior?}

### Odoo Version Compatibility

- [x] Tested on Odoo v{XX}

### Steps to Review

{How to test/verify the changes. Example: Install or upgrade module X (`-u module`), go to Inventory > Products, ...}

### Checklist

- [ ] All new models have an entry in `ir.model.access.csv`.
- [ ] No deprecated API used (`name_get()`, `attrs`, `type="json"`), verified against target Odoo version.
- [ ] Tests added or updated for changed behavior.
- [ ] OCA naming conventions followed.
- [ ] `README.md` updated if this module is user-facing.
- [ ] Version bumped in `__manifest__.py` if behavior changed (format: `{odoo}.{major}.{minor}.{patch}`).

### License

By submitting this pull request, I confirm that my contribution is made under the terms of the applicable module license ({license from __manifest__.py}).
```

---

## Component-Specific Rules

| Component           | Extra Checks                                          |
| :------------------ | :---------------------------------------------------- |
| `models/*.py`       | Security rules added? Deprecated API avoided?         |
| `views/*.xml`       | `attrs` removed? `t-raw` replaced by `t-out`?         |
| `security/*.csv`    | Every new model covered?                              |
| `tests/test_*.py`   | `TransactionCase` or `HttpCase` used correctly?       |
| `__manifest__.py`   | Version format `X.Y.A.B.C`? `license` field set?      |
| `data/*.xml`        | No hardcoded IDs? XML IDs follow `module.record_id`? |

---

## Commands

```bash
# Detect module info
grep -E "'version'|'license'|'name'" __manifest__.py

# Check what commits will be included in the PR
git log main..HEAD --oneline

# View full diff
git diff main...HEAD

# Create PR with heredoc body (recommended for multi-line)
gh pr create --title "feat: description" --body "$(cat <<'EOF'
### Context
...
EOF
)" --base main

# Create draft PR to iterate
gh pr create --draft --title "feat: description"
```

---

## Title Conventions

Follow conventional commits:
- `feat:` — New feature or Odoo module functionality
- `fix:` — Bug fix
- `docs:` — Documentation update
- `chore:` — Maintenance, version bumps, manifest updates
- `refactor:` — Code restructure, no behavior change
- `style:` — Formatting only
- `test:` — Test additions or fixes

---

## Before Creating PR

1. ✅ All CI checks pass (or are understood).
2. ✅ Version bumped in `__manifest__.py` if needed (odoo.sh uses this to trigger module update).
3. ✅ Branch is up to date with base branch (`main` or `develop`).
4. ✅ Commits are clean and follow Conventional Commits.
5. ✅ No `__pycache__` or `.pyc` files staged.

---

## ODSK Integrity Check (Only When Contributing to odoo-skills)

If the repo is `odoo-skills` specifically:
1. Verify every new `SKILL.md` has a `Skill ID` in its metadata.
2. Verify all Markdown code blocks have a language identifier.
3. Run `sync.sh` (when available) to validate UID uniqueness.

For standard Odoo module PRs, this check does NOT apply.

---

## Metadata

- **Skill ID**: ODSK-SKL-PR
- **Author**: [Geraldow](https://github.com/Geraldow)
- **Repo**: https://github.com/Yven-Labs/odoo-skills
