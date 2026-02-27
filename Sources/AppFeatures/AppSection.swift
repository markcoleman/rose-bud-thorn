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
        case .today: return "sun.max"
        case .browse: return "calendar"
        case .summaries: return "doc.text.magnifyingglass"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape"
        }
    }
}
