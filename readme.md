# Rose, Bud, Thorn

Rose, Bud, Thorn is a local-first daily reflection app for iOS, iPadOS, and macOS (Mac Catalyst), built with Swift + SwiftUI.

## Features
Core app features:
- Journal-first daily capture for Rose/Bud/Thorn with text, photos, and short videos.
- Timeline of past days with paged loading and quick navigation into day detail.
- Day detail polaroid stack with dedicated edit flow and guarded removal action.
- Local day-share image generation with native sharing flows.
- Weekly/monthly/yearly summary generation with exportable markdown artifacts.
- Optional privacy lock, reminders, prompts, and engagement insights.

Apple services leveraged:
- `iCloud Drive` (`CloudDocuments` ubiquity container) for document-store sync when available, with app-group to iCloud migration at launch.
- `App Groups` shared container for the main app, widget extension, and share extension.
- `WidgetKit` for Today widgets with deep links back into the app.
- `App Intents` + Shortcuts phrases for quick actions (capture, weekly summary/review, engagement routes).
- `Share Extension` (`com.apple.share-services`) to import one shared image directly into today's entry.
- `UserNotifications` for local daily reminder scheduling.
- `LocalAuthentication` (`LAContext`) for optional privacy lock.
- `PhotosUI`, `AVFoundation`, and `AVKit` for media capture/import experiences.
- `MessageUI` for iOS-only Messages composer flow when sharing day cards.

Device support:
- iPhone and iPad on iOS/iPadOS 26+.
- macOS 26+ via Mac Catalyst (`SUPPORTS_MACCATALYST = YES` on the main app target).
- Main app target uses `TARGETED_DEVICE_FAMILY = 1,2` (iPhone + iPad).
- Widget and share extension targets are iOS-family targets (available on iPhone/iPad builds).

iOS stuff:
- Full-screen in-app camera flow for photos and 3-second videos, including lens flip, zoom presets, and photo-library fallback.
- Selection haptics for supported interactions.
- Floating compact tab bar and compact navigation behaviors.
- Native iOS share surfaces (activity sheet + Messages composer) for day-share artifacts.

iPadOS stuff:
- Split-view shell (`NavigationSplitView`) for section navigation and detail content.
- Full camera and photo-library capture flows for journal entries.
- iPad-specific orientation support in portrait and landscape.
- Same widget, deep-link, and share-extension entry points as iPhone.

macOS stuff:
- Runs as a Mac Catalyst app with the same journal, insights, summaries, reminders, and privacy-lock flows.
- Uses split-view navigation by default for desktop-style layout.
- Media attachment on Mac uses importer flows (no iOS-style live camera capture or Messages composer).
- Local-first document storage still works, with iCloud Documents backing when available.

## Navigation
- Primary tabs: `Journal`, `Insights`.
- Settings is opened from the Insights overflow menu.
- Journal opens by default.

## Build & Test
Requirements:
- Xcode 26+
- iOS 26 / iPadOS 26 / macOS 26 deployment targets

Canonical developer entrypoints:
```bash
scripts/dev/help.sh
scripts/dev/doctor.sh
scripts/dev/bootstrap.sh
```

Package checks:
```bash
scripts/dev/package-build.sh
scripts/dev/package-test.sh
```

App build checks:
```bash
scripts/dev/app-build-ios.sh
scripts/dev/app-build-maccatalyst.sh
```

Preflight and UI checks:
```bash
scripts/dev/preflight.sh --package-only
scripts/dev/preflight.sh
scripts/dev/ui-smoke.sh
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
