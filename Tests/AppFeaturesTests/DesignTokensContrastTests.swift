import XCTest
@testable import AppFeatures

final class DesignTokensContrastTests: XCTestCase {
    func testNormalTextContrastMeetsAAGates() {
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textPrimaryOnSurfaceLight, DesignTokens.surfaceLight),
            4.5
        )
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textPrimaryOnSurfaceDark, DesignTokens.surfaceDark),
            4.5
        )

        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textSecondaryOnSurfaceLight, DesignTokens.surfaceLight),
            4.5
        )
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textSecondaryOnSurfaceDark, DesignTokens.surfaceDark),
            4.5
        )
    }

    func testLargeTextContrastMeetsAAGates() {
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textSecondaryOnSurfaceLight, DesignTokens.surfaceLight),
            3.0
        )
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textSecondaryOnSurfaceDark, DesignTokens.surfaceDark),
            3.0
        )
    }

    func testAccentTextAndEssentialBoundaryContrast() {
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textOnAccentLight, DesignTokens.interactivePrimaryLight),
            4.5
        )
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.textOnAccentDark, DesignTokens.interactivePrimaryDark),
            4.5
        )

        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.interactivePrimaryLight, DesignTokens.surfaceLight),
            3.0
        )
        XCTAssertGreaterThanOrEqual(
            contrastRatio(DesignTokens.interactivePrimaryDark, DesignTokens.surfaceDark),
            3.0
        )
    }

    private func contrastRatio(
        _ lhs: (Double, Double, Double),
        _ rhs: (Double, Double, Double)
    ) -> Double {
        let lhsLuminance = relativeLuminance(lhs)
        let rhsLuminance = relativeLuminance(rhs)
        let lighter = max(lhsLuminance, rhsLuminance)
        let darker = min(lhsLuminance, rhsLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ rgb: (Double, Double, Double)) -> Double {
        0.2126 * linearized(rgb.0) + 0.7152 * linearized(rgb.1) + 0.0722 * linearized(rgb.2)
    }

    private func linearized(_ value: Double) -> Double {
        if value <= 0.03928 {
            return value / 12.92
        }
        return pow((value + 0.055) / 1.055, 2.4)
    }
}
