# Catalyst Migration Plan

## Goal
Ship a single app target for iPhone, iPad, and Mac Catalyst.

## Phase 1 (Implemented)
- Enable Mac Catalyst support on the universal iOS target (shared scheme: `RoseBudThorn Universal`).
- Introduce `PlatformCapabilities` and `PlatformFeedback` so platform-specific behavior is centralized.
- Route media capture on Mac Catalyst to file import instead of live camera capture.
- Update root navigation layout policy so Mac Catalyst uses split navigation.
- Add GitHub Actions lanes for Mac Catalyst build and build-for-testing.

## Phase 2 (Next)
- Add explicit Catalyst-specific UX polish:
  - toolbar structure and keyboard shortcuts
  - window sizing defaults
  - pointer/context menu tuning
- Expand UI smoke tests to validate capture/browse/search/summaries flow on Catalyst.

## Phase 3 (Exit Criteria)
- Confirm feature parity across iPhone, iPad, and Catalyst Mac.
- Keep release playbook and App Store submission checklist aligned with the Universal-only target setup.
