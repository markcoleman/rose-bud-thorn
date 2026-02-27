# UX IA and Flow

## IA
- Today
- Browse
- Summaries
- Search
- Settings

## Navigation
- iPhone: `TabView` for primary sections.
- iPad/macOS: split navigation with sidebar + detail.

## Core Flow
1. Launch into Today.
2. Enter quick text for Rose/Bud/Thorn.
3. Optionally add photo and expand More for journal.
4. Auto-save and explicit save affordance.
5. Browse or search prior days.
6. Generate summaries and export markdown.

## Accessibility
- Dynamic type-compatible text styles.
- Semantic labels for category/photo actions.
- Reduced-motion safe transitions.
- Minimum 44pt target for primary actions.

## 2026 UX Design Alignment
- **Clarity first (Apple HIG):** high-contrast typography, visible hierarchy, and direct language on every capture surface.
- **Adaptive layouts by default:** `ViewThatFits` patterns for compact width, split-view support for iPad/macOS, and resilience at accessibility Dynamic Type sizes.
- **Accessible interactions:** 44pt minimum touch targets, grouped accessibility labels for brand header, and explicit hints for progressive disclosure actions.
- **Comfortable color system:** brand palette with automatic light/dark adaptations for surfaces and gradients.
- **Visual identity assets:** reusable app logo (`RoseBudLogo`) and branded header treatment for recognition across app layouts.
- **Calm motion:** preserve subtle transitions while ensuring reduced cognitive load in expanded editor states.
