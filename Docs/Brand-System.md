# Brand System

## Visual Direction
Playful botanical journaling style with vibrant candy-pastel gradients and expressive floral illustration.

## Color Tokens
- `rose`: key rose reflection color.
- `bud`: growth/future emphasis.
- `thorn`: grounded challenge tone.
- `surface`, `surfaceElevated`, `accent`, `warning`, `success`.
- Semantic roles:
`textPrimaryOnSurface`, `textSecondaryOnSurface`, `textOnAccent`,
`interactivePrimary`, `interactivePrimaryDisabled`, `focusStroke`, `dividerSubtle`.

Defined in `Sources/AppFeatures/SharedUI/DesignTokens.swift`.

## Typography
- Display: rounded/system display for warmth.
- Body: native legible body styles.

## Motion
- Subtle expand/collapse and save confirmation animation.
- Reduced-motion-safe defaults.

## Iconography System
- Source of truth: `Sources/AppFeatures/SharedUI/AppIconography.swift` (`AppIcon` enum).
- Navigation icons use outline-first symbols for scanability in tab and sidebar contexts.
- Stateful controls use outline when inactive and fill when active (for example favorite).
- Metadata and helper icons should use consistent scale/weight and secondary foreground role.
- Avoid raw `systemImage` strings in feature views; prefer semantic `AppIcon` mappings.

## Icon/Splash Guidance
- Icon: two kawaii pink roses with rainbow backdrop (`RoseBudLogo` / `AppIcon` assets).
- Launch: emblem + luminous multi-color gradient with short fade scale animation.
