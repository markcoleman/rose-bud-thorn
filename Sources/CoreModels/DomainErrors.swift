import Foundation

public enum DomainError: LocalizedError, Sendable {
    case invalidDayKey(String)
    case missingEntry(LocalDayKey)
    case corruptEntry(LocalDayKey)
    case missingAttachment(String)
    case storageFailure(String)
    case summaryFailure(String)
    case conflictArchived(String)

    public var errorDescription: String? {
        switch self {
        case .invalidDayKey(let key):
            return "Invalid day key: \(key)."
        case .missingEntry(let day):
            return "Missing entry for \(day.isoDate)."
        case .corruptEntry(let day):
            return "The entry file for \(day.isoDate) is corrupted."
        case .missingAttachment(let path):
            return "Missing attachment at \(path)."
        case .storageFailure(let reason):
            return "Storage failure: \(reason)."
        case .summaryFailure(let reason):
            return "Summary failure: \(reason)."
        case .conflictArchived(let path):
            return "Detected a conflict and archived a copy at \(path)."
        }
    }
}
