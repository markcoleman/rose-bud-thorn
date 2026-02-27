import Foundation

public enum EntryType: String, Codable, CaseIterable, Sendable {
    case rose
    case bud
    case thorn

    public var title: String {
        switch self {
        case .rose: return "Rose"
        case .bud: return "Bud"
        case .thorn: return "Thorn"
        }
    }

    public var folderName: String {
        rawValue
    }
}
