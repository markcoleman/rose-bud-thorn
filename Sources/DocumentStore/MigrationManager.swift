import Foundation
import CoreModels

public struct MigrationManager: Sendable {
    public init() {}

    public func validate(entry: EntryDay) throws {
        guard entry.schemaVersion <= EntryDay.currentSchemaVersion else {
            throw DomainError.storageFailure("Unsupported schema version \(entry.schemaVersion).")
        }
    }

    public func validate(summary: SummaryArtifact) throws {
        guard summary.schemaVersion <= SummaryArtifact.currentSchemaVersion else {
            throw DomainError.summaryFailure("Unsupported summary schema version \(summary.schemaVersion).")
        }
    }
}
