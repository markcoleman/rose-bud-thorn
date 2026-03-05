import Foundation

public enum AppSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case journal
    case insights
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .journal: return "Journal"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .journal: return AppIcon.sectionJournal.systemName
        case .insights: return AppIcon.sectionInsights.systemName
        case .settings: return AppIcon.sectionSettings.systemName
        }
    }
}
