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
    public static let surface = platformColor(
        light: (0.99, 0.96, 0.98),
        dark: (0.11, 0.11, 0.16)
    )
    public static let surfaceElevated = platformColor(
        light: (1.0, 1.0, 1.0),
        dark: (0.16, 0.17, 0.24),
        lightAlpha: 0.9,
        darkAlpha: 0.95
    )
    public static let accent = Color(red: 0.10, green: 0.72, blue: 0.86)
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
