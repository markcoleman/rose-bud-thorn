import Foundation
import CoreModels

public enum DayShareEligibility: Equatable, Sendable {
    case ready
    case missingPhotos(types: [EntryType])

    public var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }

    public var missingTypes: [EntryType] {
        switch self {
        case .ready:
            return []
        case .missingPhotos(let types):
            return types
        }
    }

    public var disabledReason: String? {
        switch self {
        case .ready:
            return nil
        case .missingPhotos:
            return "Add one photo each for Rose, Bud, and Thorn to share."
        }
    }
}
