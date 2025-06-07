//
//  DesignSystem.swift
//  rose.bud.thorn
//
//  Created by Copilot for theming standardization
//

import SwiftUI

// MARK: - Spacing Constants
enum Spacing {
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 8
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
    static let xxLarge: CGFloat = 48
    static let xxxLarge: CGFloat = 64
}

// MARK: - Design Tokens
enum DesignTokens {
    // Colors - using type-safe generated assets
    static let primaryBackground = Asset.Colors.primaryBackground
    static let secondaryBackground = Asset.Colors.secondaryBackground
    static let primaryText = Asset.Colors.primaryText
    static let secondaryText = Asset.Colors.secondaryText
    static let successColor = Asset.Colors.successColor
    static let infoColor = Asset.Colors.infoColor
    static let accentColor = Asset.Colors.accentColor
    
    // Corner Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    
    // Standard Element Sizes
    static let buttonHeight: CGFloat = 44
    static let iconSize: CGFloat = 44
    static let minimumTouchTarget: CGFloat = 44
}

// MARK: - Typography Extensions
extension Font {
    // Semantic font styles that support Dynamic Type
    static let rbtLargeTitle = Font.largeTitle
    static let rbtTitle = Font.title
    static let rbtTitle2 = Font.title2
    static let rbtTitle3 = Font.title3
    static let rbtHeadline = Font.headline
    static let rbtSubheadline = Font.subheadline
    static let rbtBody = Font.body
    static let rbtCallout = Font.callout
    static let rbtFootnote = Font.footnote
    static let rbtCaption = Font.caption
    static let rbtCaption2 = Font.caption2
}

// File: `src/Shared/Extensions/View+Accessibility.swift`
import SwiftUI

extension View {
  /// Adds a minimum touch target and VoiceOver accessibility info.
  func accessibleTouchTarget(
    label: String,
    hint: String? = nil,
    traits: AccessibilityTraits = []
  ) -> some View {
    self
      .frame(
        minWidth: DesignTokens.minimumTouchTarget,
        minHeight: DesignTokens.minimumTouchTarget
      )
      .accessibilityLabel(label)
      .accessibilityAddTraits(traits)
      .accessibilityHint(hint ?? "")
  }
}
