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
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
swift test --parallel -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

Representative app checks:
```bash
xcodebuild -project "RoseBudThorn.xcodeproj" -scheme "RoseBudThorn Universal" -destination "generic/platform=iOS Simulator" -configuration Debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project "RoseBudThorn.xcodeproj" -scheme "RoseBudThorn Universal" -destination "platform=macOS,variant=Mac Catalyst" -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Regression List
- DST and leap-day boundaries.
- Missing file behavior.
- Corrupt JSON behavior.
- Capture/edit/save flow integrity.
- Day detail open/remove/edit behavior.
- Insights/settings navigation and launch deep links.
