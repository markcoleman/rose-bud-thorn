# PRD — Rose, Bud, Thorn

## Problem
Users need a fast, private daily reflection flow that supports short capture and deeper journaling with lookback and period summaries.

## MVP Scope
- Daily capture for Rose/Bud/Thorn with optional photos.
- Journal expansion for each item.
- Browse by calendar + timeline.
- Search with text + category + has-photo filter.
- Generate, view, export, and regenerate week/month/year summaries.
- Local/offline-first persistence in document store.

## V1 Scope
- Richer summary templates.
- Analytics views (tags/mood trends).
- Widget/shortcut deep links.
- Conflict resolution UI.

## Acceptance Criteria
- App launches to Today capture.
- Entry persistence survives relaunch.
- Attachments persist and load.
- Summary artifacts persist as Markdown and are regenerable.
- No external services required for core workflow.

## Edge Cases
- Corrupt entry file recovery.
- Missing attachments.
- DST/leap-day boundary grouping.
- Conflict archive with non-destructive merge behavior.
