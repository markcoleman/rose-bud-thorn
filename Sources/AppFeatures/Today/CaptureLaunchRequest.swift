import Foundation
import CoreModels

public struct CaptureLaunchRequest: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let type: EntryType
    public let source: String?

    public init(id: UUID = UUID(), type: EntryType, source: String? = nil) {
        self.id = id
        self.type = type
        self.source = source
    }
}
