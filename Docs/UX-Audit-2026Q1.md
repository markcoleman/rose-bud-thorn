# UX Audit 2026 Q1

## Scope
- Platform priority: iPhone first; validate iPad/macOS behavior after compact-width pass.
- IA constraint: existing 5-section architecture remains intact.
- Standards: 44x44pt minimum touch targets, SF Symbols semantic consistency, WCAG AA contrast gates.

## Scoring Rubric
- `Tap Target`: Effective touch area >=44x44pt (`Pass` / `Needs Work`).
- `Hierarchy`: Primary action prominence and low CTA competition (`Pass` / `Needs Work`).
- `Iconography`: Semantic consistency with `AppIcon` mappings (`Pass` / `Needs Work`).
- `Color/Contrast`: semantic token usage and AA readiness (`Pass` / `Needs Work`).

## Screen-by-Screen Matrix

| Surface | Key Controls | Tap Target | Hierarchy | Iconography | Color/Contrast | Notes |
|---|---|---|---|---|---|---|
| `RootAppView` | tab bar, lock overlay unlock | Pass | Pass | Pass | Pass | Lock icon/actions moved to semantic icon and touch token sizing. |
| `TodayCaptureView` | share/favorite/actions | Pass | Pass | Pass | Pass | High-frequency icons normalized to semantic catalog. |
| `EntryRowCard` | `More/Done`, add capture, media remove | Pass | Pass | Pass | Pass | Plain buttons now use explicit minimum touch target modifier. |
| `MomentCameraView` | close, flip camera, capture, zoom chips | Pass | Pass | Pass | Pass | 40pt preview close raised to 44pt; top controls normalized. |
| `BrowseShellView` | mode picker, refresh, day detail jump | Pass | Pass | Pass | Pass | Toolbar refresh icon now semantic with touch target guard. |
| `CalendarBrowseView` | day grid, older/newer entry | Pass | Pass | Pass | Pass | Day cells converted to true buttons with 44pt minimum targets. |
| `TimeCapsuleBrowseView` | filter chips, capture today CTA | Pass | Pass | Pass | Pass | CTA icon routed through semantic icon catalog. |
| `YearRailView` | year chips | Pass | Pass | Pass | Pass | Chips now enforce minimum compact touch target. |
| `MemoryDayCardView` | card row and metadata icons | Pass | Pass | Pass | Pass | Metadata and favorite icon styling aligned with semantic roles. |
| `SummaryListView` | generate/review controls | Pass | Pass | Pass | Pass | Empty-state and CTA icons now from semantic catalog. |
| `DayDetailView` | share/save | Pass | Pass | Pass | Pass | Share actions use semantic icon mappings. |
| `SettingsView` | toggles, pickers, privacy actions | Pass | Pass | Pass | Pass | Existing control sizing already acceptable in `Form`. |
| `SearchView` | search input + execute button | Pass | Pass | Pass | Pass | Search icon unified with section semantic icon. |
| `EngagementHubView` | resurfaced memory action row | Pass | Pass | Pass | Pass | Removed small control sizing and enforced compact target minimum. |

## Contrast Checklist (Manual States)
- [x] Light mode: `textPrimaryOnSurface` on `surface` >= 4.5:1.
- [x] Dark mode: `textPrimaryOnSurface` on `surface` >= 4.5:1.
- [x] Light mode: `textSecondaryOnSurface` on `surface` >= 4.5:1.
- [x] Dark mode: `textSecondaryOnSurface` on `surface` >= 4.5:1.
- [x] Accent action label/icon (`textOnAccent` on `interactivePrimary`) >= 4.5:1.
- [x] Essential control boundary/icon contrast (`interactivePrimary` vs `surface`) >= 3:1.
- [x] Pressed/disabled/selected states mapped to semantic roles (`interactivePrimaryDisabled`, `focusStroke`, `dividerSubtle`).

## Backlog (Implementation-Ready)

## P0
- Keep all compact-width plain-button controls on shared `touchTargetMinSize`.
- Prevent regressions by retaining contrast gate tests in `DesignTokensContrastTests`.

## P1
- Continue replacing residual raw SF Symbol strings in low-frequency views.
- Introduce optional icon weight/scale helper in shared UI to enforce metadata consistency.

## P2
- Expand UI automation for additional compact-width hit-testing scenarios (camera and browse variants).

## Acceptance Report
- Build:
  - `swift build` -> Pass
  - `xcodebuild -project RoseBudThorn.xcodeproj -scheme "RoseBudThorn Universal" -destination "generic/platform=iOS Simulator" -configuration Debug CODE_SIGNING_ALLOWED=NO build` -> Pass
- Unit tests:
  - `swift test --filter AppFeaturesTests` -> Pass (`39` tests, `0` failures)
  - Contrast gates validated in `Tests/AppFeaturesTests/DesignTokensContrastTests.swift` -> Pass
- UI tests:
  - `UITests/AccessibilitySmokeUITests.swift` and `UITests/CaptureDayFlowUITests.swift` were extended for tap-target/discoverability checks.
  - Xcode schemes available in this repo are not configured with a runnable `test` action for the iOS app schemes from CLI in this environment (`RoseBudThornApp` and `RoseBudThorn Universal` both report no test action), so execution status is `Blocked` for simulator-run UI tests.

Overall status: `Pass` for current scope (`Audit + Backlog` with implementation of high-priority fixes).
