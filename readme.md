# Rose, Bud, Thorn

Rose, Bud, Thorn is a local-first daily reflection app for iOS, iPadOS, and macOS built with Swift + SwiftUI.

## Features
- Unified Journal surface with:
  - Search bar and inline filters (All/Rose/Bud/Thorn, Photos, Favorites).
  - Expanded Today capture card at the top.
  - Paged past-day timeline cards below.
- Fast daily capture for Rose, Bud, Thorn with quick text + optional photo.
- Search across entry text with index-backed filtering.
- Weekly/monthly/yearly summary generation and regeneration.
- Local document-store persistence in `Documents` with iCloud Drive container fallback support.
- Optional biometric/device authentication lock.

## Navigation Model
- Primary tabs: `Journal`, `Insights`, `Settings`.
- App launches into `Journal`.
- Journal navigation:
  - Top search field uses a debounced query (`~300ms`).
  - Today card is always first and editable.
  - Past day cards open `DayDetailView`.
  - Search state persists when opening and returning from day detail.

## Search Notes
- Default (empty query): Journal shows full paged timeline (today + past days).
- Non-empty query: Journal switches to search mode and shows matching day cards inline.
- Filters:
  - Category: `All`, `Rose`, `Bud`, `Thorn`
  - `Photos` (has media)
  - `Favorites`
- Search uses the local index first and falls back to entry scanning if index lookup fails.

## Performance Notes
- Timeline is paged in chunks (default page size: `45` days).
- Search is debounced to avoid blocking scroll interactions.
- Day summaries are hydrated in batches; canonical source-of-truth remains document files.

## Repository Structure
- `Package.swift`: multi-module Swift package.
- `Sources/CoreModels`: canonical domain types and protocols.
- `Sources/CoreDate`: day/period key logic and timezone-safe date helpers.
- `Sources/DocumentStore`: file layout, CRUD, atomic write, attachments, conflict archive.
- `Sources/SearchIndex`: derivative searchable index.
- `Sources/Summaries`: deterministic summary generation and persistence.
- `Sources/AppFeatures`: SwiftUI feature screens and view models.
- `Sources/RoseBudThornApp`: app entry point.
- `Tests/*`: unit and integration tests.
- `Docs/*`: PRD, UX, ADR, QA plan, brand, and migration strategy (including Catalyst migration plan).

## Build and Test
Requirements:
- Xcode 26 toolchain (Swift 5.10+)
- iOS 26 / iPadOS 26 / macOS 26 minimum deployment targets

Commands:
```bash
swift build
swift test
```

Run the app target (macOS):
```bash
swift run RoseBudThornApp
```

In Xcode:
1. Open [`RoseBudThorn.xcworkspace`](/Users/markcoleman/Development/github/rose-bud-thorn/RoseBudThorn.xcworkspace).
2. Choose target/scheme:
   - `RoseBudThorn Universal` for iPhone, iPad, and Mac Catalyst
3. In `Signing & Capabilities`, set your Apple Team and keep automatic signing enabled.

Mac Catalyst CLI build:
```bash
xcodebuild \
  -project "RoseBudThorn.xcodeproj" \
  -scheme "RoseBudThorn Universal" \
  -destination "platform=macOS,variant=Mac Catalyst" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Bundle identifier strategy:
- Universal app target (iPhone/iPad/Mac Catalyst): `com.example.rosebudthorn`
- Widget extension: `com.example.rosebudthorn.widgets`

## Data Storage
Canonical store:
```text
Documents/
  Entries/YYYY/MM/DD/entry.json
  Entries/YYYY/MM/DD/{rose|bud|thorn}/attachments/*
  Summaries/{weekly|monthly|yearly}/{key}.md
  Summaries/{weekly|monthly|yearly}/{key}.json
  Index/index.json
  Conflicts/YYYY-MM-DD/*.json
  Exports/
```

Notes:
- Entries are canonical; summaries and index are derived.
- Writes use temp + replace for atomicity.
- Conflict snapshots are archived before merge overwrite.

## Architecture Notes
- Source of truth: document files in app storage.
- Derivative search index: rebuildable from entries.
- Async actor-based persistence services.
- Journal data source and view model keep timeline/search orchestration off the main scroll path.
- Deterministic summary generation from entry corpus only.

See [`Docs/ADR-001-LocalDocumentStore.md`](Docs/ADR-001-LocalDocumentStore.md).

## Extending
- Add new entry metadata fields by bumping `schemaVersion` and updating `MigrationManager`.
- Swap search index storage by implementing `SearchIndex`.
- Add richer summary templates in `SummaryMarkdownRenderer`.

## Quality Gates
Current state:
- `swift build`: passing.
- `swift test`: passing (`15` tests).
- Core modules covered: models, date keys/ranges, document CRUD, attachments, search, summaries, capture flow.

## Known Gaps
- UI tests in `UITests/` are provided as XCUITest stubs and are not executed by SwiftPM.
- You must set a valid Apple Team + provisioning for physical iPhone deployment.
