# TestFlight + Xcode Cloud (Hybrid Rollout)

This repo uses a hybrid pipeline:

- GitHub Actions remains the source of truth for PR and branch CI.
- Xcode Cloud handles signed iOS archives and TestFlight distribution.

## Scope

Phase 1 scope is iOS TestFlight only. macOS distribution is intentionally out of scope.

## Repo Wiring

Custom Xcode Cloud scripts are checked in at:

- `ci_scripts/ci_post_clone.sh`
- `ci_scripts/ci_pre_xcodebuild.sh`

These scripts implement:

- dependency resolution (`swift package resolve`)
- pre-archive quality gate (`swift test --parallel`)
- no-op behavior outside Xcode Cloud so they can be run locally without side effects

## Bundle IDs (iOS + widget)

The placeholder identifiers were replaced with:

- iOS app: `com.rosebudthorn.ios`
- iOS widget: `com.rosebudthorn.ios.widgets`

If your production App Store Connect records use different identifiers, update them in `RoseBudThorn.xcodeproj/project.pbxproj` before first upload.

## Xcode Cloud Workflow Setup

Create two workflows in Xcode Cloud:

## 1) iOS Internal TestFlight

- Product: `RoseBudThorn.xcodeproj`
- Scheme: `RoseBudThorn Universal`
- Action: `Archive`
- Destination: `Any iOS Device (arm64)`
- Configuration: `Release`
- Start condition: `On changes to branch main`
- Post-action distribution: `TestFlight Internal Testers`
- Build number: enable automatic increment in workflow settings

## 2) iOS Beta Candidate

- Product: `RoseBudThorn.xcodeproj`
- Scheme: `RoseBudThorn Universal`
- Action: `Archive`
- Destination: `Any iOS Device (arm64)`
- Configuration: `Release`
- Start condition: `Manual`
- Post-action distribution: `TestFlight` (internal first)

External tester rollout remains manual in App Store Connect after internal validation.

## Required Apple Setup

Before first cloud upload:

1. Confirm active Apple Developer Program membership.
2. Create/verify App Store Connect app for bundle ID `com.rosebudthorn.ios`.
3. Ensure widget bundle ID `com.rosebudthorn.ios.widgets` is attached to the app record.
4. Keep Automatic Signing enabled for iOS and widget targets.
5. Confirm the intended team is selected for cloud signing.

## Versioning Contract

- `MARKETING_VERSION`: manually bump for each beta/release line.
- `CURRENT_PROJECT_VERSION`: keep numeric and monotonic.
- Xcode Cloud workflow should auto-increment build number on each archive.

## Operational Contract

- PR merge gate: GitHub Actions must be green.
- Distribution gate: Xcode Cloud archive must be green and pass `swift test --parallel`.
- `main` branch: automatic internal TestFlight uploads.
- `release/*` branches: use manual `iOS Beta Candidate` workflow as needed.

## Validation Checklist

Use this checklist after enabling workflows:

1. Push to `main` and verify `iOS Internal TestFlight` starts.
2. Confirm a signed archive is produced (app + widget).
3. Confirm build appears in App Store Connect TestFlight.
4. Trigger a second run and confirm build number is greater than the previous run.
5. Confirm internal tester install succeeds on a device.
6. Manually trigger `iOS Beta Candidate` and verify it uploads correctly.
