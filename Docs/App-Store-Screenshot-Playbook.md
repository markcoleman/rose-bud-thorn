# App Store Screenshot Playbook

This project now includes an automated screenshot pipeline that captures UI screens and composes styled App Store-ready images with device framing.

## Ideal target sizes

Based on Apple App Store Connect screenshot specifications (checked March 21, 2026):

- iPhone (6.9" display, required when shipping iPhone):
  - Accepted portrait sizes: `1260 x 2736`, `1290 x 2796`, `1320 x 2868`
  - Pipeline target: `1320 x 2868`
- iPad (13" display, required when shipping iPad):
  - Accepted portrait sizes: `2064 x 2752`, `2048 x 2732`
  - Pipeline target: `2064 x 2752`

## What the pipeline generates

- 5 curated scenes per device class:
  - Onboarding hero
  - Today capture
  - Journal timeline
  - Day detail
  - Insights
- Styled marketing composition:
  - Device bezel/frame treatment (iPhone/iPad specific)
  - Gradient visual direction per scene
  - Headline and feature chips
  - Exact App Store upload dimensions

## Run

From repository root:

```bash
scripts/dev/app-store-screenshots.sh
```

Output paths:

- `AppStoreAssets/final/iphone-6.9-1320x2868`
- `AppStoreAssets/final/ipad-13-2064x2752`
