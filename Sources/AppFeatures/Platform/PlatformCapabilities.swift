import Foundation

public enum PlatformCapabilities {
    #if targetEnvironment(macCatalyst)
    public static let isMacCatalyst = true
    #else
    public static let isMacCatalyst = false
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    public static let supportsLiveCameraCapture = true
    #else
    public static let supportsLiveCameraCapture = false
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    public static let supportsSelectionHaptics = true
    #else
    public static let supportsSelectionHaptics = false
    #endif
}
