# Migration Strategy

## Schema Versioning
- `EntryDay.schemaVersion`
- `SummaryArtifact.schemaVersion`

## Rules
- Additive changes should provide defaults.
- Breaking changes require migration logic in `MigrationManager`.
- Unsupported future schema versions fail with explicit user-facing error.

## Recovery
- If index schema changes, rebuild index from entries.
- If summary schema changes, regenerate from entries.

## Rollout
1. Add new fields with defaults.
2. Bump schema versions.
3. Update migration validator and tests.
