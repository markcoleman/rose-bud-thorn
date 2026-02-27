import Foundation
import CoreModels
import CoreDate

public actor EntryStore {
    private let entries: EntryRepository
    private let attachments: AttachmentRepository
    private let index: SearchIndex

    public init(entries: EntryRepository, attachments: AttachmentRepository, index: SearchIndex) {
        self.entries = entries
        self.attachments = attachments
        self.index = index
    }

    public func load(day: LocalDayKey) async throws -> EntryDay {
        if let entry = try await entries.load(day: day) {
            return entry
        }
        return EntryDay.empty(dayKey: day)
    }

    public func save(_ entry: EntryDay) async throws {
        try await entries.save(entry)
        try await index.upsert(entry)
    }

    public func delete(day: LocalDayKey) async throws {
        try await entries.delete(day: day)
        try await index.remove(day: day)
    }

    public func list(range: DateInterval?) async throws -> [LocalDayKey] {
        try await entries.list(range: range)
    }

    public func search(_ query: EntrySearchQuery) async throws -> [LocalDayKey] {
        try await index.search(query)
    }

    public func rebuildIndex() async throws {
        try await index.rebuildFromEntries()
    }

    public func importPhoto(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> PhotoRef {
        try await attachments.importImage(from: sourceURL, day: day, type: type)
    }

    public func removePhoto(_ ref: PhotoRef, day: LocalDayKey) async throws {
        try await attachments.remove(ref, day: day)
    }
}
