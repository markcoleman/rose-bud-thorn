import Foundation

public enum AppSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case journal
    case insights

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .journal: return "Journal"
        case .insights: return "Insights"
        }
    }

    public var systemImage: String {
        switch self {
        case .journal: return AppIcon.sectionJournal.systemName
        case .insights: return AppIcon.sectionInsights.systemName
        }
    }
}
