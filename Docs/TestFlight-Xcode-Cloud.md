# TestFlight + Xcode Cloud (Hybrid)

This repo uses a hybrid delivery model:
- GitHub Actions: merge gates, package checks, app builds, and UI automation lanes.
- Xcode Cloud: signed archive and TestFlight distribution.

## Repo Wiring
Xcode Cloud helper scripts:
- `ci_scripts/ci_post_clone.sh`
- `ci_scripts/ci_pre_xcodebuild.sh`

Script behavior:
- Resolve Swift package dependencies via `scripts/dev/bootstrap.sh`.
- Run a pre-archive package test gate via `scripts/dev/package-test.sh`.
- Exit safely when not running in Xcode Cloud (`CI_XCODE_CLOUD != TRUE`).

## Bundle IDs
Current bundle identifiers:
- iOS app: `com.rosebudthorn.ios`
- Widget: `com.rosebudthorn.ios.widgets`

## Recommended Xcode Cloud Workflows
1. Internal TestFlight
- Product: `RoseBudThorn.xcodeproj`
- Scheme: `RoseBudThorn Universal`
- Action: `Archive`
- Destination: `Any iOS Device (arm64)`
- Configuration: `Release`
- Trigger: changes on `main`
- Distribution: Internal TestFlight testers

2. Beta Candidate (Manual)
- Product: `RoseBudThorn.xcodeproj`
- Scheme: `RoseBudThorn Universal`
- Action: `Archive`
- Destination: `Any iOS Device (arm64)`
- Configuration: `Release`
- Trigger: Manual
- Distribution: TestFlight

## Operational Contract
- GitHub Actions must be green before merge.
- Xcode Cloud archive must be green before distribution.
- Build number should auto-increment for each cloud archive.
