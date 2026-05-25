---
title: Odoo 18 — Mixins Reference
domain: mixins
version: 18.0
edition: both
source: native
status: active
---

# Odoo 18 — Mixins Reference

Mixins are abstract models designed to be inherited by other models to provide reusable functionality.

## `mail.thread`
Adds chatter functionality, including messaging, followers, and logging.

- **Inheritance**: `_inherit = ['mail.thread']`
- **Key Methods**:
    - `message_post(body, subject, message_type='notification', ...)`: Post a message to the chatter.
    - `message_subscribe(partner_ids)`: Add followers.
- **Fields Added**: `message_ids`, `message_follower_ids`.

## `mail.activity.mixin`
Adds activity management (tasks, calls, emails) to a model.

- **Inheritance**: `_inherit = ['mail.thread', 'mail.activity.mixin']` (usually used together).
- **Key Methods**:
    - `activity_schedule(activity_type_id, date_deadline, summary, ...)`: Schedule a new activity.
- **Fields Added**: `activity_ids`, `activity_state`, `activity_type_id`.

## `website.published.mixin`
Provides tools to manage the publication of records on a website.

- **Inheritance**: `_inherit = ['website.published.mixin']`
- **Fields Added**:
    - `website_published` (Boolean): Whether the record is visible to public users.
    - `website_url` (Compute): The URL to view the record on the frontend.
- **Methods**: `website_publish_button()` (toggles publication state).

## `portal.mixin`
Simplifies the creation of portal access and links for records.

- **Inheritance**: `_inherit = ['portal.mixin']`
- **Key Methods**:
    - `get_portal_url()`: Returns the portal URL for the record.
    - `_compute_access_url()`: Computes the `access_url` field.

## `rating.mixin`
Allows users to rate records (e.g., projects, helpdesk tickets).

- **Inheritance**: `_inherit = ['rating.mixin']`
- **Key Methods**:
    - `rating_get_stats()`: Returns a summary of ratings (average, count).
    - `rating_apply(rate, partner_id, ...)`: Post a new rating.
- **Fields Added**: `rating_ids`, `rating_last_value`.

## `utm.mixin`
Adds UTM tracking fields (Source, Medium, Campaign).

- **Fields Added**: `campaign_id`, `source_id`, `medium_id`.
- **Inheritance**: `_inherit = ['utm.mixin']`
- Use it for lead generation, sales, or any model that needs to track marketing origins.
