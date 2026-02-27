# Test Plan

## Unit Coverage
- `CoreModelsTests`: codable and model invariants.
- `CoreDateTests`: timezone/day/week/month/year calculations.
- `DocumentStoreTests`: CRUD, merge, conflict archive, attachment lifecycle.
- `SearchIndexTests`: indexing, querying, rebuild.
- `SummariesTests`: generation, persistence, markdown content.

## Integration Coverage
- `AppFeaturesTests`: capture flow persistence and search experience.

## UI Tests
- XCUITest stubs under `UITests/` cover capture happy path and accessibility smoke checks.
- Full iOS/iPad/mac UI automation wiring is left for Xcode project target integration.

## Regression List
- DST and leap-day boundaries.
- Missing file behavior.
- Corrupt JSON behavior.
- Rebuild search index after index loss.
