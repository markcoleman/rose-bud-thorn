import Foundation
import Observation
import CoreModels

@MainActor
@Observable
public final class DayDetailViewModel {
    public let dayKey: LocalDayKey
    public var entry: EntryDay
    public var expandedTypes: Set<EntryType> = Set(EntryType.allCases)
    public var errorMessage: String?
    public var isSaving = false

    private let environment: AppEnvironment

    public init(environment: AppEnvironment, dayKey: LocalDayKey) {
        self.environment = environment
        self.dayKey = dayKey
        self.entry = EntryDay.empty(dayKey: dayKey)
    }

    public func load() async {
        do {
            entry = try await environment.entryStore.load(day: dayKey)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateShortText(_ text: String, for type: EntryType) {
        var item = entry.item(for: type)
        item.shortText = text
        item.updatedAt = .now
        entry.setItem(item, for: type)
        entry.updatedAt = .now
    }

    public func updateJournal(_ text: String, for type: EntryType) {
        var item = entry.item(for: type)
        item.journalTextMarkdown = text
        item.updatedAt = .now
        entry.setItem(item, for: type)
        entry.updatedAt = .now
    }

    public func importPhoto(from sourceURL: URL, for type: EntryType) async {
        do {
            let ref = try await environment.entryStore.importPhoto(from: sourceURL, day: dayKey, type: type)
            var item = entry.item(for: type)
            item.photos.append(ref)
            item.updatedAt = .now
            entry.setItem(item, for: type)
            entry.updatedAt = .now
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func removePhoto(_ ref: PhotoRef, for type: EntryType) async {
        do {
            try await environment.entryStore.removePhoto(ref, day: dayKey)
            var item = entry.item(for: type)
            item.photos.removeAll { $0.id == ref.id }
            item.updatedAt = .now
            entry.setItem(item, for: type)
            entry.updatedAt = .now
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await environment.entryStore.save(entry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func photoURL(for ref: PhotoRef) -> URL {
        environment.photoURL(for: ref, day: dayKey)
    }
}
