---
title: Version Matrix
domain: devops
version: all
edition: both
source: native
status: active
---

# Version Matrix

A comprehensive compatibility guide for Odoo versions, supporting infrastructure, and lifecycle status.

## 1. Core Compatibility Matrix

| Odoo Version | Python Version | PostgreSQL | OS Support | Status |
| :--- | :--- | :--- | :--- | :--- |
| **v18 (Master)** | 3.10 - 3.12+ | 13 - 16 | Ubuntu 22.04+ | Development |
| **v17** | 3.10 - 3.12 | 12 - 16 | Ubuntu 22.04 | Stable |
| **v16** | 3.8 - 3.10 | 12 - 15 | Ubuntu 20.04+ | Stable |
| **v15** | 3.7 - 3.9 | 10 - 14 | Ubuntu 20.04 | Security Only |
| **v14** | 3.6 - 3.8 | 10 - 13 | Ubuntu 18.04+ | EOL |

## 2. Key Technical Milestones

- **v17:** Removal of `attrs`, introduction of new Web Client (Search, Views), advanced JS expression engine.
- **v16:** Performance overhaul (ORM, CSS), introduction of Owl v2, new "Dark Mode" native support.
- **v15:** OWL as the default frontend framework, `assets` manifest key replaces XML asset bundles.
- **v14:** Transition to Python 3.8+ as recommended, start of the OWL migration.

## 3. End of Life (EOL) & Support
Odoo officially supports the **last three stable versions**.
- **v17, v16, v15** are currently supported (as of May 2024).
- Once **v18** is released (Oct 2024), **v15** will reach EOL.
- EOL versions do not receive security patches or bug fixes from Odoo SA.

## 4. Database Requirements
- **PostgreSQL 12+** is highly recommended for all active versions due to performance improvements in indexing and JSON handling.
- **Unaccent** and **Trigram** extensions should be enabled for optimized searching.

## 5. JavaScript / Frontend Evolution
- **v17+:** Pure OWL, removal of most jQuery/Widget legacy.
- **v14-v16:** Hybrid state (Widget.js + OWL).
- **v13 and below:** Backbone.js / Widget.js (Legacy).
