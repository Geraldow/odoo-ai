---
name: odoo-ci
description: >
  Manages GitHub Actions CI workflows for Odoo projects including lint, tests, and PR gates.
  Trigger: When investigating failing CI jobs, editing .github/workflows/, or working with Odoo CI pipelines.
license: MIT
model: sonnet
metadata:
  author: Geraldow
  version: "2.0.0"
  scope: [root]
  auto_invoke:
    - "Inspect or debug a GitHub Actions job failing on a PR"
    - "Edit or understand .github/workflows/"
    - "Work with Odoo CI lint or test pipeline"
    - "Understand how version bumps trigger module updates on odoo.sh"
---

## What This Skill Covers

Use this skill whenever you are:

- Reading or changing GitHub Actions workflows under `.github/workflows/`
- Debugging why a CI job is failing (lint, tests, pre-commit)
- Understanding how the release pipeline works for Odoo modules
- Working with odoo.sh deployment triggers via version bump

---

## Quick Map (Where to Look)

| Thing to Understand              | File / Location                                        |
| :------------------------------- | :----------------------------------------------------- |
| Lint / static analysis           | `.github/workflows/ci.yml` (or `pre-commit-config.yaml`) |
| Automated tests                  | `tests/test_*.py` + CI `--test-enable` flag            |
| Module version source of truth   | `__manifest__.py` (field `version`)                    |
| odoo.sh module update trigger    | Version bump in `__manifest__.py` (odoo.sh detects it) |

---

## Typical Odoo CI Pipeline

Runs on every **push** and every **PR**.

### Common Steps

| Step               | What It Validates                                      | Common Failure Reason                                |
| :----------------- | :----------------------------------------------------- | :--------------------------------------------------- |
| `pre-commit` / OCA | `pylint-odoo`, `flake8`, XML checks, manifest lint     | Deprecated API used, missing fields, wrong format    |
| `--test-enable`    | All `TransactionCase` / `HttpCase` tests in the module | Test assertion failed, missing `ir.model.access.csv` |
| `--stop-after-init`| Module installs without error                          | XML parse error, missing dependency, bad field def   |

### Debug Checklist

1. Find the failing step in GitHub Actions UI.
2. Read the exact error message (file name and line number shown).
3. Check path filters — is the workflow supposed to run for your changed files?
4. Common quick fixes:
   - **Pylint error**: Read the rule and fix the violation (never silence unless justified).
   - **Test failure**: Run `--test-enable -u module` locally, read the traceback.
   - **Install error**: Check `__manifest__.py` for missing `depends`, bad XML IDs, or field errors.
   - **Missing access rule**: Add the model to `ir.model.access.csv`.

---

## odoo.sh Deployment Trigger

odoo.sh uses the module **version field** to decide whether to run `-u module` on deploy.

```text
Branch pushed to odoo.sh
        ↓
odoo.sh reads __manifest__.py version
        ↓
Version changed?  → YES → runs odoo with -u module (applies DB changes)
                  → NO  → only restarts server (no schema migration)
```

### Version Format

```text
{odoo_major}.{major}.{minor}.{patch}

Examples:
  18.0.1.0.0  → initial release
  18.0.1.1.0  → new feature (minor bump)
  18.0.1.1.1  → bug fix (patch bump)
```

**Rule**: Always bump the version in `__manifest__.py` when your change:
- Adds or modifies model fields
- Adds or modifies views, security rules, or data files
- Changes behavior the user will observe

---

## Release Pipeline Pattern (GitHub Releases)

If the project uses automated GitHub Releases:

```text
PR merged to main
       ↓
release.yml reads last stable git tag
       ↓
Analyzes commits since that tag (conventional commits)
       ↓
Determines bump: MAJOR / MINOR / PATCH
       ↓
Creates GitHub Release with tag vX.Y.Z
```

### Version Bump Rules

| Commit Pattern                          | Bump Type | Example           |
| :-------------------------------------- | :-------- | :---------------- |
| `feat:` or `feat(scope):`               | MINOR     | `1.0.0` → `1.1.0` |
| `fix:` / `docs:` / `chore:` / `style:`  | PATCH     | `1.0.0` → `1.0.1` |
| `feat!:` / `BREAKING CHANGE:` in body   | MAJOR     | `1.0.0` → `2.0.0` |

---

## Key Rules

- NEVER manually create git tags when a release pipeline is configured.
- NEVER modify already-released versions in `CHANGELOG.md` once tagged.
- ALWAYS bump `__manifest__.py` version when behavior or DB schema changes.
- NEVER skip `--test-enable` to force a broken deploy through.

---

## Metadata

- **Skill ID**: ODSK-SKL-CI
- **Author**: [Geraldow](https://github.com/Geraldow)
- **Repo**: https://github.com/Yven-Labs/odoo-skills
