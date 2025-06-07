# Design System Documentation

## Overview

Rose Bud Thorn uses a centralized design system to ensure consistency, accessibility, and maintainability across the entire app. This system includes standardized colors, typography, spacing, and accessibility helpers.

## Color Tokens

All colors are defined in `Assets.xcassets` with both light and dark mode variants:

### Available Colors
- `PrimaryBackground` - Main background color 
- `SecondaryBackground` - Secondary surfaces
- `PrimaryText` - Primary text color
- `SecondaryText` - Secondary/muted text
- `SuccessColor` - Success states (green)
- `InfoColor` - Information states (blue)  
- `AccentColor` - Brand accent color

### Usage
```swift
// Use via DesignTokens for consistency
.background(DesignTokens.primaryBackground)
.foregroundColor(DesignTokens.primaryText)

// Or via generated Assets enum for type safety
.background(Asset.Colors.primaryBackground)
```

## Typography

All text uses semantic fonts that support Dynamic Type:

```swift
Text("Title").font(.rbtTitle)
Text("Body text").font(.rbtBody) 
Text("Caption").font(.rbtCaption)
```

### Available Fonts
- `.rbtLargeTitle`, `.rbtTitle`, `.rbtTitle2`, `.rbtTitle3`
- `.rbtHeadline`, `.rbtSubheadline`
- `.rbtBody`, `.rbtCallout`
- `.rbtFootnote`, `.rbtCaption`, `.rbtCaption2`

## Spacing

Consistent spacing using progressive scale:

```swift
.padding(Spacing.small)    // 12pt
.padding(Spacing.medium)   // 16pt
.padding(Spacing.large)    // 24pt
```

### Available Spacing
- `xxSmall` (4pt), `xSmall` (8pt), `small` (12pt)
- `medium` (16pt), `large` (24pt), `xLarge` (32pt)
- `xxLarge` (48pt), `xxxLarge` (64pt)

## Accessibility

### Minimum Touch Targets
All interactive elements use 44pt minimum touch target:

```swift
Button("Action") { }
.accessibleTouchTarget(label: "Action", hint: "Performs an action")
```

### VoiceOver Support
- All interactive elements have `.accessibilityLabel`
- Decorative elements marked with `.decorativeAccessibility()`
- Semantic elements use `.accessibilityAddTraits(.isHeader)`

### Dynamic Type
All text automatically scales with user's preferred text size via semantic fonts.

## Code Generation

SwiftGen automatically generates type-safe asset access:

```bash
# Run SwiftGen to regenerate assets
swiftgen config run --config swiftgen.yml
```

## Testing

Design system is validated via unit tests:
- Color token availability
- Spacing progression 
- Font accessibility
- Snapshot tests for light/dark modes

## Best Practices

1. **Always use design tokens** instead of hard-coded colors
2. **Use semantic fonts** instead of fixed sizes  
3. **Apply consistent spacing** via Spacing enum
4. **Add accessibility labels** to all interactive elements
5. **Test with VoiceOver** and large text sizes
6. **Validate in both light and dark modes**