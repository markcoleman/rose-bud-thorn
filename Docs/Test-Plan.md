# Test Plan

## Package Coverage
- `CoreModelsTests`: codable invariants and model behavior.
- `CoreDateTests`: timezone/day/week/month/year calculations.
- `DocumentStoreTests`: CRUD, merge, conflict archive, attachment lifecycle.
- `SummariesTests`: summary generation and persistence.
- `AppFeaturesTests`: feature orchestration (capture flow, reminders, prompts, onboarding, insights, sharing).

## UI Coverage
- `UITests/` source files are wired to `RoseBudThornUITests` in the Xcode project.
- PR lane runs a deterministic smoke subset.
- Nightly lane runs the broader UI suite.

## Primary Commands
```bash
scripts/dev/package-build.sh
scripts/dev/package-test.sh
```

Representative app checks:
```bash
scripts/dev/app-build-ios.sh
scripts/dev/app-build-maccatalyst.sh
scripts/dev/ui-smoke.sh
```

## Regression List
- DST and leap-day boundaries.
- Missing file behavior.
- Corrupt JSON behavior.
- Capture/edit/save flow integrity.
- Day detail open/remove/edit behavior.
- Insights/settings navigation and launch deep links.
