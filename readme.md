# Rose, Bud, Thorn

Rose, Bud, Thorn is a local-first daily reflection app for iOS, iPadOS, and macOS built with Swift + SwiftUI.

## Features
- Unified Journal surface with:
  - Search bar and inline filters (All/Rose/Bud/Thorn, Photos, Favorites).
  - Expanded Today capture card at the top.
  - Paged past-day timeline cards below.
- Fast daily capture for Rose, Bud, Thorn with quick text + optional photo.
- Polaroid Stack Day View for existing days:
  - Read-only by default with horizontal Rose/Bud/Thorn flip.
  - Separate `Edit` screen for deliberate modifications.
  - Destructive `Remove` action guarded by confirmation.
- Day sharing as a composite Polaroid stack image (header + three stacked cards + subtle branding).
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
- Day detail navigation:
  - Existing days open in a read-focused Polaroid stack pager.
  - `Edit` pushes a separate editor view (no inline edits on the stack screen).

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
- Polaroid cards downsample and cache photo assets for smoother horizontal paging.
- Share rendering generates a local PNG stack (`~1080px` wide by default) via `ImageRenderer` using local files only.

## Polaroid Day + Share
- Day header shows localized full date and actions: `Share`, `Edit`, and overflow `Remove`.
- Polaroid pager:
  - Cards are `Rose`, `Bud`, `Thorn` in fixed order.
  - Each card has category marker, square photo region (or placeholder), and caption.
  - Reduced Motion disables tilt/3D effects while preserving page navigation.
- Share flow:
  - Generates a single composite image for the day.
  - iOS uses `UIActivityViewController` for natural iMessage entry.
  - macOS/iPad fall back to `ShareLink` sheet path where appropriate.
  - Works offline; no network dependencies.

## Future Enhancements
- Optional duplicate/export actions in the day overflow menu.
- Inline snippet highlighting inside share cards for query-based exports.
- Richer branded themes for share stack templates.

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
