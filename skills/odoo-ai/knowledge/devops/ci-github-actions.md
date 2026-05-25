---
title: GitHub Actions CI for Odoo
domain: devops
version: 18.0
edition: both
source: odoo-contribute
status: active
priority: P3
---

# GitHub Actions CI for Odoo

Automate linting, testing, and containerization of your Odoo modules.

## Typical Pipeline

| Step | Validates |
|---|---|
| Checkout | Repository content |
| Python setup | Runtime compatibility |
| pre-commit | Formatting, lint (pylint-odoo), manifest, XML |
| Odoo install/update | Module can load without errors |
| Odoo tests | Execution of `TransactionCase` and `HttpCase` |

## Lint and Test Workflow

```yaml
name: CI
on: [push, pull_request]
jobs:
  tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
        with: {python-version: '3.12'}
      - name: Install Dependencies
        run: |
          pip install -r https://github.com/odoo/odoo/raw/18.0/requirements.txt
          pip install pylint-odoo
      - name: Run Pylint
        run: pylint --load-plugins=pylint_odoo -d all -e odoo_addons custom_addons/
      - name: Run Odoo Tests
        run: |
          # Simplified: requires a running Postgres
          python3 odoo-bin --test-enable --stop-after-init -d test_db -i custom_module
```

## Build Docker Image Workflow

```yaml
  build-image:
    needs: tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: myreg.com/odoo-custom:latest
```

## Debug Checklist

1. Identify the failing job and exact step.
2. Read the first real traceback or lint message.
3. Map the failure to file and module.
4. Reproduce locally with the same command.
5. Fix the root cause, not only the CI symptom.
