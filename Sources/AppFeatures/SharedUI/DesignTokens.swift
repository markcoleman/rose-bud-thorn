import SwiftUI

public enum DesignTokens {
    public static let rose = Color(red: 0.86, green: 0.33, blue: 0.43)
    public static let bud = Color(red: 0.33, green: 0.64, blue: 0.42)
    public static let thorn = Color(red: 0.49, green: 0.36, blue: 0.33)
    public static let surface = Color(red: 0.97, green: 0.95, blue: 0.92)
    public static let surfaceElevated = Color.white.opacity(0.85)
    public static let accent = Color(red: 0.16, green: 0.44, blue: 0.55)
    public static let warning = Color.orange
    public static let success = Color.green

    public static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.90, blue: 0.86),
            Color(red: 0.89, green: 0.95, blue: 0.91)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
