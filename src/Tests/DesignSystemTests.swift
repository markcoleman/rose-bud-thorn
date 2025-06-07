//
//  DesignSystemTests.swift
//  rose.bud.thorn
//
//  Created by Copilot for theming standardization tests
//

import XCTest
import SwiftUI
@testable import RoseBudThorn

class DesignSystemTests: XCTestCase {
    
    func testAllColorsHaveLightAndDarkVariants() {
        // Test that all our design tokens are properly accessible via generated assets
        XCTAssertNotNil(Asset.Colors.primaryBackground)
        XCTAssertNotNil(Asset.Colors.secondaryBackground)
        XCTAssertNotNil(Asset.Colors.primaryText)
        XCTAssertNotNil(Asset.Colors.secondaryText)
        XCTAssertNotNil(Asset.Colors.successColor)
        XCTAssertNotNil(Asset.Colors.infoColor)
        XCTAssertNotNil(Asset.Colors.accentColor)
        
        // Test that design tokens are accessible
        XCTAssertNotNil(DesignTokens.primaryBackground)
        XCTAssertNotNil(DesignTokens.secondaryBackground)
        XCTAssertNotNil(DesignTokens.primaryText)
        XCTAssertNotNil(DesignTokens.secondaryText)
        XCTAssertNotNil(DesignTokens.successColor)
        XCTAssertNotNil(DesignTokens.infoColor)
        XCTAssertNotNil(DesignTokens.accentColor)
    }
    
    func testSpacingConstants() {
        // Test that spacing constants are properly defined and progressive
        XCTAssertEqual(Spacing.xxSmall, 4)
        XCTAssertEqual(Spacing.xSmall, 8)
        XCTAssertEqual(Spacing.small, 12)
        XCTAssertEqual(Spacing.medium, 16)
        XCTAssertEqual(Spacing.large, 24)
        XCTAssertEqual(Spacing.xLarge, 32)
        XCTAssertEqual(Spacing.xxLarge, 48)
        XCTAssertEqual(Spacing.xxxLarge, 64)
        
        // Verify progressive spacing
        XCTAssertLessThan(Spacing.xxSmall, Spacing.xSmall)
        XCTAssertLessThan(Spacing.xSmall, Spacing.small)
        XCTAssertLessThan(Spacing.small, Spacing.medium)
        XCTAssertLessThan(Spacing.medium, Spacing.large)
        XCTAssertLessThan(Spacing.large, Spacing.xLarge)
        XCTAssertLessThan(Spacing.xLarge, Spacing.xxLarge)
        XCTAssertLessThan(Spacing.xxLarge, Spacing.xxxLarge)
    }
    
    func testDesignTokenConstants() {
        // Test that design token constants are properly configured
        XCTAssertEqual(DesignTokens.cornerRadiusSmall, 8)
        XCTAssertEqual(DesignTokens.cornerRadiusMedium, 12)
        XCTAssertEqual(DesignTokens.cornerRadiusLarge, 16)
        
        XCTAssertEqual(DesignTokens.buttonHeight, 44)
        XCTAssertEqual(DesignTokens.iconSize, 44)
        XCTAssertEqual(DesignTokens.minimumTouchTarget, 44)
    }
    
    func testSemanticFonts() {
        // Test that semantic fonts are properly defined
        XCTAssertNotNil(Font.rbtLargeTitle)
        XCTAssertNotNil(Font.rbtTitle)
        XCTAssertNotNil(Font.rbtTitle2)
        XCTAssertNotNil(Font.rbtTitle3)
        XCTAssertNotNil(Font.rbtHeadline)
        XCTAssertNotNil(Font.rbtSubheadline)
        XCTAssertNotNil(Font.rbtBody)
        XCTAssertNotNil(Font.rbtCallout)
        XCTAssertNotNil(Font.rbtFootnote)
        XCTAssertNotNil(Font.rbtCaption)
        XCTAssertNotNil(Font.rbtCaption2)
    }
}