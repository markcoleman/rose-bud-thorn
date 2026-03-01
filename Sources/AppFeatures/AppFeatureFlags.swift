import Foundation

public struct AppFeatureFlags: Sendable, Codable, Equatable {
    public var remindersEnabled: Bool
    public var streaksEnabled: Bool
    public var widgetsEnabled: Bool
    public var insightsEnabled: Bool
    public var resurfacingEnabled: Bool
    public var commitmentsEnabled: Bool
    public var os26UIEnabled: Bool

    public init(
        remindersEnabled: Bool = true,
        streaksEnabled: Bool = true,
        widgetsEnabled: Bool = true,
        insightsEnabled: Bool = true,
        resurfacingEnabled: Bool = true,
        commitmentsEnabled: Bool = true,
        os26UIEnabled: Bool = true
    ) {
        self.remindersEnabled = remindersEnabled
        self.streaksEnabled = streaksEnabled
        self.widgetsEnabled = widgetsEnabled
        self.insightsEnabled = insightsEnabled
        self.resurfacingEnabled = resurfacingEnabled
        self.commitmentsEnabled = commitmentsEnabled
        self.os26UIEnabled = os26UIEnabled
    }
}
