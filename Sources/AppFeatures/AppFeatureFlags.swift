import Foundation

public struct AppFeatureFlags: Sendable {
    public var remindersEnabled: Bool
    public var streaksEnabled: Bool
    public var widgetsEnabled: Bool

    public init(
        remindersEnabled: Bool = true,
        streaksEnabled: Bool = true,
        widgetsEnabled: Bool = true
    ) {
        self.remindersEnabled = remindersEnabled
        self.streaksEnabled = streaksEnabled
        self.widgetsEnabled = widgetsEnabled
    }
}
