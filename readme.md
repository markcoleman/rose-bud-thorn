# Rose, Bud, Thorn

Rose, Bud, Thorn is a local-first daily reflection app for iOS, iPadOS, and macOS (Mac Catalyst), built with Swift + SwiftUI.

## Features
- Journal-first daily capture for Rose/Bud/Thorn with text, photos, and short videos.
- Timeline of past days with paged loading and quick navigation into day detail.
- Day detail polaroid stack with dedicated edit flow and guarded removal action.
- Local day-share image generation and native share sheet flows.
- Weekly/monthly/yearly summary generation with exportable markdown artifacts.
- Optional privacy lock, reminders, prompts, and engagement insights.
- Widget + App Intents support for fast entry points.
- Share extension import flow for adding a shared photo into today's entry.

## Navigation
- Primary tabs: `Journal`, `Insights`.
- Settings is opened from the Insights overflow menu.
- Journal opens by default.

## Build & Test
Requirements:
- Xcode 26+
- iOS 26 / iPadOS 26 / macOS 26 deployment targets

Swift package checks:
```bash
swift build -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
swift test --parallel -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

Xcode app build checks:
```bash
xcodebuild \
  -project "RoseBudThorn.xcodeproj" \
  -scheme "RoseBudThorn Universal" \
  -destination "generic/platform=iOS Simulator" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project "RoseBudThorn.xcodeproj" \
  -scheme "RoseBudThorn Universal" \
  -destination "platform=macOS,variant=Mac Catalyst" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

UI smoke test example:
```bash
xcodebuild \
  -project "RoseBudThorn.xcodeproj" \
  -scheme "RoseBudThorn Universal" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:RoseBudThornUITests/RoseBudThornUITests/testFirstLaunchShowsOnboardingThenSkipOpensToday \
  test
```

## Repository Structure
- `Package.swift`: module graph.
- `App/`: app target sources, assets, entitlements, widgets, share extension.
- `Sources/CoreModels`: canonical domain types and protocols.
- `Sources/CoreDate`: day/period key logic and timezone-safe helpers.
- `Sources/DocumentStore`: file layout, CRUD, atomic writes, attachments, migrations.
- `Sources/Summaries`: deterministic summary generation and persistence.
- `Sources/AppFeatures`: SwiftUI feature surfaces and app orchestration.
- `Sources/RoseBudThornApp`: Swift package executable entrypoint.
- `Tests/*`: package unit/integration tests.
- `UITests/*`: UI automation source files wired to Xcode UI test target.
- `Docs/*`: operational docs and runbooks.

## Data Storage
Canonical store:
```text
Documents/
  Entries/YYYY/MM/DD/entry.json
  Entries/YYYY/MM/DD/{rose|bud|thorn}/attachments/*
  Summaries/{weekly|monthly|yearly}/{key}.md
  Summaries/{weekly|monthly|yearly}/{key}.json
  Conflicts/YYYY-MM-DD/*.json
  Exports/
```

Notes:
- Entries are canonical data.
- Summaries are derived artifacts that can be regenerated.
- Writes use temp + replace semantics for atomicity.

## CI & Distribution
- GitHub Actions: PR/push quality gates (package checks, app builds, UI smoke).
- Nightly canary: extended checks including full UI lane.
- Xcode Cloud: signed archive + TestFlight distribution flow.

See:
- `Docs/ADR-001-LocalDocumentStore.md`
- `Docs/Migration-Strategy.md`
- `Docs/Test-Plan.md`
- `Docs/TestFlight-Xcode-Cloud.md`

## Known Gaps
- Physical-device deployment still requires valid Apple Team and provisioning setup.
