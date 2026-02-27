import Foundation

public protocol EntryRepository: Sendable {
    func load(day: LocalDayKey) async throws -> EntryDay?
    func save(_ entry: EntryDay) async throws
    func delete(day: LocalDayKey) async throws
    func list(range: DateInterval?) async throws -> [LocalDayKey]
}

public protocol AttachmentRepository: Sendable {
    func importImage(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> PhotoRef
    func remove(_ ref: PhotoRef, day: LocalDayKey) async throws
}

public protocol SearchIndex: Sendable {
    func upsert(_ entry: EntryDay) async throws
    func remove(day: LocalDayKey) async throws
    func search(_ query: EntrySearchQuery) async throws -> [LocalDayKey]
    func rebuildFromEntries() async throws
}

public protocol SummaryService: Sendable {
    func generate(period: SummaryPeriod, key: String) async throws -> SummaryArtifact
    func load(period: SummaryPeriod, key: String) async throws -> SummaryArtifact?
    func list(period: SummaryPeriod) async throws -> [SummaryArtifact]
}
