# ADR-001: Local Document Store as Canonical Source

## Status
Accepted

## Context
The app requires offline-first behavior, user-owned files, iCloud Drive compatibility, and zero external backend.

## Decision
- Canonical data in file-based `Documents` store.
- Use JSON for entries and summary metadata.
- Use Markdown for summary artifacts.
- Keep search index derivative and rebuildable.
- Isolate persistence through actors and async APIs.

## Tradeoffs
Pros:
- Transparent storage and easy export/backup.
- Offline reliability.
- Privacy by default.

Cons:
- Conflict complexity under multi-device sync.
- Need explicit migration strategy for schema evolution.

## Consequences
- `entry.json` is source of truth.
- Conflicts are archived non-destructively.
- Summaries/index can be regenerated from entries.
