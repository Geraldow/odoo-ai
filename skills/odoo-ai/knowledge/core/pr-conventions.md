---
title: Pull Request Conventions
domain: core
version: 18.0
edition: both
source: odoo-contribute
status: complete
priority: P2
---

# Pull Request Conventions

## Required Context

Before creating a PR:
- Read `__manifest__.py` for module name, version, and license.
- Determine Odoo major version from the manifest.
- Review `git diff main...HEAD` or the configured base branch.
- Confirm branch safety and push authorization.

## PR Template

```markdown
### Context

Why this change exists and what business/technical issue it solves.

### Description

- Module: `{module}`
- Odoo Version: `v{major}`
- Edition: `Community` or `Enterprise`
- Breaking Change: `Yes/No`

### Steps to Review

1. Install or upgrade `{module}`.
2. Navigate to the exact menu.
3. Validate the expected behavior.

### Checklist

- [ ] New models have ACLs.
- [ ] No deprecated API for the target Odoo version.
- [ ] Tests or manual verification are documented.
- [ ] OCA naming conventions followed.
- [ ] Version bumped when behavior, views, security, or schema changed.
```

## gh Commands

```bash
gh pr create --draft --title "feat: concise title"
gh pr create --base produccion --title "fix: concise title" --body-file pr.md
gh pr view --web
```

Do not create a PR until commits are clean and the target branch is confirmed.
