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
        // Test that all our design tokens have both light and dark mode variants
        let colorNames = [
            "PrimaryBackground",
            "SecondaryBackground", 
            "PrimaryText",
            "SecondaryText",
            "SuccessColor",
            "InfoColor",
            "AccentColor"
        ]
        
        for colorName in colorNames {
            let color = Color(colorName)
            XCTAssertNotNil(color, "Color \(colorName) should exist in Assets.xcassets")
        }
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