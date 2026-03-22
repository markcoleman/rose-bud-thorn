import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum DesignTokens {
    public static let rose = Color(red: 0.95, green: 0.30, blue: 0.72)
    public static let bud = Color(red: 0.24, green: 0.80, blue: 0.49)
    public static let thorn = Color(red: 0.40, green: 0.34, blue: 0.86)

    static let surfaceLight: (Double, Double, Double) = (0.99, 0.96, 0.98)
    static let surfaceDark: (Double, Double, Double) = (0.11, 0.11, 0.16)
    public static let surface = platformColor(
        light: surfaceLight,
        dark: surfaceDark
    )
    public static let surfaceElevated = platformColor(
        light: (1.0, 1.0, 1.0),
        dark: (0.16, 0.17, 0.24),
        lightAlpha: 0.9,
        darkAlpha: 0.95
    )

    static let textPrimaryOnSurfaceLight: (Double, Double, Double) = (0.16, 0.10, 0.23)
    static let textPrimaryOnSurfaceDark: (Double, Double, Double) = (0.97, 0.96, 0.99)
    public static let textPrimaryOnSurface = platformColor(
        light: textPrimaryOnSurfaceLight,
        dark: textPrimaryOnSurfaceDark
    )

    static let textSecondaryOnSurfaceLight: (Double, Double, Double) = (0.35, 0.28, 0.45)
    static let textSecondaryOnSurfaceDark: (Double, Double, Double) = (0.77, 0.78, 0.86)
    public static let textSecondaryOnSurface = platformColor(
        light: textSecondaryOnSurfaceLight,
        dark: textSecondaryOnSurfaceDark
    )

    static let textOnAccentLight: (Double, Double, Double) = (1.0, 1.0, 1.0)
    static let textOnAccentDark: (Double, Double, Double) = (1.0, 1.0, 1.0)
    public static let textOnAccent = platformColor(
        light: textOnAccentLight,
        dark: textOnAccentDark
    )

    static let interactivePrimaryLight: (Double, Double, Double) = (0.24, 0.33, 0.77)
    static let interactivePrimaryDark: (Double, Double, Double) = (0.31, 0.40, 0.86)
    public static let interactivePrimary = platformColor(
        light: interactivePrimaryLight,
        dark: interactivePrimaryDark
    )

    public static let interactivePrimaryDisabled = platformColor(
        light: (0.63, 0.66, 0.75),
        dark: (0.34, 0.36, 0.45)
    )

    public static let focusStroke = platformColor(
        light: interactivePrimaryLight,
        dark: (0.58, 0.67, 0.98),
        lightAlpha: 0.65,
        darkAlpha: 0.75
    )

    public static let dividerSubtle = platformColor(
        light: (0.16, 0.13, 0.22),
        dark: (0.96, 0.96, 0.99),
        lightAlpha: 0.12,
        darkAlpha: 0.18
    )

    public static let accent = interactivePrimary
    public static let warning = Color(red: 0.99, green: 0.62, blue: 0.33)
    public static let success = Color(red: 0.49, green: 0.86, blue: 0.33)

    public static let backgroundGradient = LinearGradient(
        colors: [
            platformColor(
                light: (0.99, 0.82, 0.91),
                dark: (0.28, 0.14, 0.31)
            ),
            platformColor(
                light: (1.0, 0.95, 0.66),
                dark: (0.20, 0.21, 0.35)
            ),
            platformColor(
                light: (0.73, 0.97, 0.84),
                dark: (0.10, 0.23, 0.24)
            ),
            platformColor(
                light: (0.68, 0.85, 1.0),
                dark: (0.13, 0.17, 0.35)
            ),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let journalCompactBackgroundGradient = LinearGradient(
        colors: [
            platformColor(
                light: (0.37, 0.19, 0.58),
                dark: (0.21, 0.10, 0.32)
            ),
            platformColor(
                light: (0.30, 0.16, 0.51),
                dark: (0.16, 0.10, 0.28)
            ),
            platformColor(
                light: (0.24, 0.14, 0.43),
                dark: (0.11, 0.08, 0.23)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let journalCompactSurface = platformColor(
        light: (0.27, 0.16, 0.41),
        dark: (0.20, 0.12, 0.31),
        lightAlpha: 0.82,
        darkAlpha: 0.88
    )

    public static let journalCompactSurfaceElevated = platformColor(
        light: (0.31, 0.19, 0.46),
        dark: (0.23, 0.14, 0.35),
        lightAlpha: 0.90,
        darkAlpha: 0.92
    )

    public static let journalCompactProgressTrack = platformColor(
        light: (0.41, 0.28, 0.56),
        dark: (0.30, 0.20, 0.44),
        lightAlpha: 0.85,
        darkAlpha: 0.90
    )

    public static let journalCompactProgressFill = Color(red: 0.96, green: 0.56, blue: 0.83)

    public static func contentHorizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<390:
            return 12
        case ..<500:
            return 16
        case ..<900:
            return 20
        default:
            return 28
        }
    }

    public static func contentTopPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<390:
            return 8
        case ..<500:
            return 10
        case ..<900:
            return 12
        default:
            return 14
        }
    }

    public static func contentBottomPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<390:
            return 16
        case ..<500:
            return 18
        default:
            return 20
        }
    }

    public static let tabSwipeHorizontalDominanceRatio: CGFloat = 1.3
    public static let tabSwipeMinimumTranslation: CGFloat = 80
    public static let tabSwipePredictedEndThreshold: CGFloat = 140

    private static func platformColor(
        light: (Double, Double, Double),
        dark: (Double, Double, Double),
        lightAlpha: Double = 1,
        darkAlpha: Double = 1
    ) -> Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: dark.0, green: dark.1, blue: dark.2, alpha: darkAlpha)
            }
            return UIColor(red: light.0, green: light.1, blue: light.2, alpha: lightAlpha)
        })
        #elseif os(macOS)
        return Color(NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(red: dark.0, green: dark.1, blue: dark.2, alpha: darkAlpha)
            }
            return NSColor(red: light.0, green: light.1, blue: light.2, alpha: lightAlpha)
        })
        #else
        return Color(red: light.0, green: light.1, blue: light.2, opacity: lightAlpha)
        #endif
    }
}
