---
title: Odoo 19 — Mixins Reference
domain: mixins
version: 19.0
edition: both
source: native
status: active
---

# Odoo 19 — Mixins Reference

Mixins are abstract models that provide standardized, reusable business logic and UI features through inheritance.

## `mail.thread`
The foundation for collaborative features. It adds the "Chatter" widget to the bottom of forms.

- **Usage**: `_inherit = ['mail.thread']`
- **Capabilities**:
    - **Message Logging**: `message_post(body="...")`
    - **Followers**: Tracks who receives notifications for the record.
    - **Tracking**: Automatically logs changes to fields marked with `tracking=True`.
- **Key Fields**: `message_ids`, `message_follower_ids`.

## `mail.activity.mixin`
Enables task and schedule management (Activities) for a record.

- **Usage**: `_inherit = ['mail.thread', 'mail.activity.mixin']`
- **Capabilities**:
    - Scheduling next actions (Calls, Emails, Tasks).
    - Status tracking (Overdue, Today, Planned).
- **Key Methods**: `activity_schedule()`, `activity_reschedule()`.

## `portal.mixin`
Provides tools for sharing records with external portal users.

- **Usage**: `_inherit = ['portal.mixin']`
- **Capabilities**:
    - Generates unique access URLs and tokens.
    - Standardizes the `access_url` and `access_token` fields.
- **Key Methods**: `get_portal_url()`, `_compute_access_url()`.

## `website.published.mixin`
Used for models that need a public frontend presence (e.g., Blog Posts, Products).

- **Usage**: `_inherit = ['website.published.mixin']`
- **Fields Added**:
    - `website_published`: Boolean control for visibility.
    - `website_url`: Computed frontend path.
- **Method**: `website_publish_button()` (logic for the "Publish" toggle).

## `utm.mixin`
Integrates marketing tracking into any model.

- **Usage**: `_inherit = ['utm.mixin']`
- **Fields**: `campaign_id`, `source_id`, `medium_id`.
- **Purpose**: Essential for Sales, Leads, and Subscriptions to track conversion origins.

## `rating.mixin`
Adds customer satisfaction (CSAT) rating capabilities.

- **Usage**: `_inherit = ['rating.mixin']`
- **Capabilities**:
    - Sending rating requests via email.
    - Storing and aggregating numerical and emoji feedback.
- **Key Method**: `rating_get_stats()`.

## `image.mixin`
Standardizes the handling of record images with automatic resizing for different resolutions (small, medium, large).

- **Usage**: `_inherit = ['image.mixin']`
- **Fields**: `image_1920`, `image_1024`, `image_512`, `image_256`, `image_128`.
- **Logic**: Uploading to `image_1920` automatically populates the smaller variants.
