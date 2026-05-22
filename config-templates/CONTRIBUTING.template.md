# Contributing — Authorized Contributors

> **Setup instructions**: Copy this file to  
> `~/.claude/skills/odoo-development/CONTRIBUTING.md`  
> and fill in your team's data. This file is LOCAL — never commit it to your project repos.

---

## Team members

Fill in one entry per authorized contributor:

```
- **Name**: {Full Name}
  - **GitHub**: {github-username}
  - **Email(s)**: {email@domain.com}
  - **Role**: developer | tech_lead | consultant
```

Example:

```
- **Name**: Jane Smith
  - **GitHub**: janesmith
  - **Email(s)**: jane@mycompany.com
  - **Role**: tech_lead
```

---

## Authorized projects

List the GitHub orgs or repos this team works on:

```
- {github-org}/{repo-name}
- {github-org}/{repo-name}
```

---

## Git authorization rules

Before any commit or push in a project from this team:

1. Verify `git config user.name` matches a Name in the list above.
2. Verify `git config user.email` matches an Email in the list above.
3. Verify `gh api user --jq .login` matches a GitHub handle in the list above.

If no match is found → **STOP and alert the user before proceeding.**

---

## Notes

- Add or remove contributors as your team changes.
- Each team member should have their own copy with the same list (it is read-only context for Claude).
- Roles are for context only — they do not affect git permissions.
