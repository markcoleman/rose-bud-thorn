import Foundation

public enum SummaryLaunchAction: String, Codable, Sendable {
    case openCurrentWeeklySummary
    case startWeeklyReview
}

public struct SummaryLaunchRequest: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let action: SummaryLaunchAction
    public let source: String?

    public init(id: UUID = UUID(), action: SummaryLaunchAction, source: String? = nil) {
        self.id = id
        self.action = action
        self.source = source
    }
}
