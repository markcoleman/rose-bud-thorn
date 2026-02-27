import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public enum DesignTokens {
    public static let rose = Color(red: 0.86, green: 0.33, blue: 0.43)
    public static let bud = Color(red: 0.33, green: 0.64, blue: 0.42)
    public static let thorn = Color(red: 0.49, green: 0.36, blue: 0.33)
    public static let surface = platformColor(
        light: (0.97, 0.95, 0.92),
        dark: (0.12, 0.13, 0.15)
    )
    public static let surfaceElevated = platformColor(
        light: (1.0, 1.0, 1.0),
        dark: (0.18, 0.19, 0.22),
        lightAlpha: 0.9,
        darkAlpha: 0.95
    )
    public static let accent = Color(red: 0.16, green: 0.44, blue: 0.55)
    public static let warning = Color.orange
    public static let success = Color.green

    public static let backgroundGradient = LinearGradient(
        colors: [
            platformColor(
                light: (0.94, 0.90, 0.86),
                dark: (0.09, 0.10, 0.12)
            ),
            platformColor(
                light: (0.89, 0.95, 0.91),
                dark: (0.13, 0.15, 0.17)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

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
