import Foundation
import CoreModels

public enum DayShareEligibility: Equatable, Sendable {
    case ready
    case emptyDay

    public var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }

    public var missingTypes: [EntryType] {
        []
    }

    public var disabledReason: String? {
        switch self {
        case .ready:
            return nil
        case .emptyDay:
            return "Add reflection text or media before sharing this day."
        }
    }
}
