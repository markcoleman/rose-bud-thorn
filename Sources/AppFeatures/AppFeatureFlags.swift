import Foundation

public struct AppFeatureFlags: Sendable, Codable, Equatable {
    public var remindersEnabled: Bool
    public var streaksEnabled: Bool
    public var widgetsEnabled: Bool
    public var insightsEnabled: Bool
    public var resurfacingEnabled: Bool
    public var commitmentsEnabled: Bool
    public var os26UIEnabled: Bool
    public var browseTimeCapsuleEnabled: Bool

    public init(
        remindersEnabled: Bool = true,
        streaksEnabled: Bool = true,
        widgetsEnabled: Bool = true,
        insightsEnabled: Bool = true,
        resurfacingEnabled: Bool = true,
        commitmentsEnabled: Bool = true,
        os26UIEnabled: Bool = true,
        browseTimeCapsuleEnabled: Bool = true
    ) {
        self.remindersEnabled = remindersEnabled
        self.streaksEnabled = streaksEnabled
        self.widgetsEnabled = widgetsEnabled
        self.insightsEnabled = insightsEnabled
        self.resurfacingEnabled = resurfacingEnabled
        self.commitmentsEnabled = commitmentsEnabled
        self.os26UIEnabled = os26UIEnabled
        self.browseTimeCapsuleEnabled = browseTimeCapsuleEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case remindersEnabled
        case streaksEnabled
        case widgetsEnabled
        case insightsEnabled
        case resurfacingEnabled
        case commitmentsEnabled
        case os26UIEnabled
        case browseTimeCapsuleEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        remindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? true
        streaksEnabled = try container.decodeIfPresent(Bool.self, forKey: .streaksEnabled) ?? true
        widgetsEnabled = try container.decodeIfPresent(Bool.self, forKey: .widgetsEnabled) ?? true
        insightsEnabled = try container.decodeIfPresent(Bool.self, forKey: .insightsEnabled) ?? true
        resurfacingEnabled = try container.decodeIfPresent(Bool.self, forKey: .resurfacingEnabled) ?? true
        commitmentsEnabled = try container.decodeIfPresent(Bool.self, forKey: .commitmentsEnabled) ?? true
        os26UIEnabled = try container.decodeIfPresent(Bool.self, forKey: .os26UIEnabled) ?? true
        browseTimeCapsuleEnabled = try container.decodeIfPresent(Bool.self, forKey: .browseTimeCapsuleEnabled) ?? true
    }
}
