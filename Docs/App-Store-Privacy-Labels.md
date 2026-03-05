# App Store Privacy Labels

This file captures the recommended App Store Connect privacy answers for the current app implementation.

## Recommendation (Current Codebase)

- `Data Collected`: `No`
- `Tracking`: `No`

## Why This Is The Current Recommendation

- No networking or third-party telemetry SDKs are present in the app targets.
- Journal content, tags, moods, media references, and summaries are stored in the local app-group container.
- Usage analytics are stored on-device in `UserDefaults` (`LocalAnalyticsStore`) and are not uploaded.
- Camera, microphone, and photo library access are used to create and attach local media, not to transmit data off-device.

## Evidence Pointers

- Local analytics only: `Sources/AppFeatures/Analytics/LocalAnalyticsStore.swift`
- Local document storage (app group): `Sources/DocumentStore/DocumentStoreConfiguration.swift`
- iOS app uses app-group configuration: `Clients/Apple/RoseBudThornAppleApp.swift`
- Camera/microphone/photo usage declarations: `RoseBudThorn.xcodeproj/project.pbxproj`

## App Store Connect Inputs

In App Store Connect (`App Privacy` section):

1. Select `No, we do not collect data from this app`.
2. Confirm `Tracking` is `No`.

## When To Revisit

Update these answers immediately if any of the following are added:

- Remote analytics/crash reporting/telemetry
- Cloud sync or backend APIs that transmit user or usage data off-device
- Ads or attribution SDKs
- Account systems that collect identifiers or contact info
