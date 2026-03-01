import Foundation

#if os(iOS)
import UIKit
#endif

public enum PlatformFeedback {
    public static func selectionChanged() {
        guard PlatformCapabilities.supportsSelectionHaptics else { return }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
}
