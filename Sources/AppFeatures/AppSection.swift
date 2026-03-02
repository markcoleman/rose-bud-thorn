import Foundation

public enum AppSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case today
    case browse
    case summaries
    case search
    case settings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today: return "Today"
        case .browse: return "Browse"
        case .summaries: return "Summaries"
        case .search: return "Search"
        case .settings: return "Settings"
        }
    }

    public var systemImage: String {
        switch self {
        case .today: return AppIcon.sectionToday.systemName
        case .browse: return AppIcon.sectionBrowse.systemName
        case .summaries: return AppIcon.sectionSummaries.systemName
        case .search: return AppIcon.sectionSearch.systemName
        case .settings: return AppIcon.sectionSettings.systemName
        }
    }
}
