import Foundation

public enum SummaryPeriod: String, Codable, CaseIterable, Sendable {
    case week
    case month
    case year

    public var storageFolder: String {
        switch self {
        case .week: return "weekly"
        case .month: return "monthly"
        case .year: return "yearly"
        }
    }

    public var title: String {
        switch self {
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .year: return "Yearly"
        }
    }
}

public struct SummaryArtifact: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let period: SummaryPeriod
    public let key: String
    public let generatedAt: Date
    public let contentMarkdown: String
    public let highlights: [String]
    public let photoRefs: [PhotoRef]

    public init(
        schemaVersion: Int = SummaryArtifact.currentSchemaVersion,
        period: SummaryPeriod,
        key: String,
        generatedAt: Date,
        contentMarkdown: String,
        highlights: [String],
        photoRefs: [PhotoRef]
    ) {
        self.schemaVersion = schemaVersion
        self.period = period
        self.key = key
        self.generatedAt = generatedAt
        self.contentMarkdown = contentMarkdown
        self.highlights = highlights
        self.photoRefs = photoRefs
    }
}
