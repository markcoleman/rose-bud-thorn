import Foundation
import CoreModels

public struct MigrationManager: Sendable {
    public init() {}

    public func validate(entry: EntryDay) throws {
        guard entry.schemaVersion <= EntryDay.currentSchemaVersion else {
            throw DomainError.storageFailure("Unsupported schema version \(entry.schemaVersion).")
        }
    }

    public func migrate(entry: EntryDay) -> EntryDay {
        guard entry.schemaVersion < EntryDay.currentSchemaVersion else {
            return entry
        }

        return EntryDay(
            schemaVersion: EntryDay.currentSchemaVersion,
            dayKey: entry.dayKey,
            roseItem: entry.roseItem,
            budItem: entry.budItem,
            thornItem: entry.thornItem,
            tags: entry.tags,
            mood: entry.mood,
            createdAt: entry.createdAt,
            updatedAt: entry.updatedAt
        )
    }

    public func validate(summary: SummaryArtifact) throws {
        guard summary.schemaVersion <= SummaryArtifact.currentSchemaVersion else {
            throw DomainError.summaryFailure("Unsupported summary schema version \(summary.schemaVersion).")
        }
    }
}
