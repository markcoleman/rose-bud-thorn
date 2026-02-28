import Foundation
import Observation
import CoreModels
import CoreDate

@MainActor
@Observable
public final class TodayViewModel {
    public private(set) var dayKey: LocalDayKey
    public var entry: EntryDay
    public var expandedTypes: Set<EntryType> = []
    public var isLoading = false
    public var isSaving = false
    public var errorMessage: String?
    public var lastSavedAt: Date?

    private let environment: AppEnvironment
    private let dayCalculator: DayKeyCalculator
    private var saveTask: Task<Void, Never>?

    public init(environment: AppEnvironment, now: Date = .now) {
        self.environment = environment
        self.dayCalculator = environment.dayCalculator
        let initialDayKey = environment.dayCalculator.dayKey(for: now)
        self.dayKey = initialDayKey
        self.entry = EntryDay.empty(dayKey: initialDayKey, now: now)
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            dayKey = dayCalculator.dayKey(for: .now)
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
        scheduleAutosave()
    }

    public func updateJournalText(_ text: String, for type: EntryType) {
        var item = entry.item(for: type)
        item.journalTextMarkdown = text
        item.updatedAt = .now
        entry.setItem(item, for: type)
        entry.updatedAt = .now
        scheduleAutosave()
    }

    public func setMood(_ mood: Int?) {
        entry.mood = mood
        entry.updatedAt = .now
        scheduleAutosave()
    }

    public func setTags(from raw: String) {
        let tags = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        entry.tags = Array(Set(tags)).sorted()
        entry.updatedAt = .now
        scheduleAutosave()
    }

    public func toggleFavorite() {
        entry.favorite.toggle()
        entry.updatedAt = .now
        scheduleAutosave()
    }

    public func importPhoto(from sourceURL: URL, for type: EntryType) async {
        do {
            try await importPhotoNow(from: sourceURL, for: type, targetDay: dayKey)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func importPhotoNow(from sourceURL: URL, for type: EntryType, targetDay: LocalDayKey) async throws {
        if targetDay == dayKey {
            let ref = try await environment.entryStore.importPhoto(from: sourceURL, day: dayKey, type: type)
            var item = entry.item(for: type)
            item.photos.append(ref)
            item.updatedAt = .now
            entry.setItem(item, for: type)
            entry.updatedAt = .now
            try await saveNow()
            return
        }

        var targetEntry = try await environment.entryStore.load(day: targetDay)
        let ref = try await environment.entryStore.importPhoto(from: sourceURL, day: targetDay, type: type)
        var item = targetEntry.item(for: type)
        item.photos.append(ref)
        item.updatedAt = .now
        targetEntry.setItem(item, for: type)
        targetEntry.updatedAt = .now
        try await environment.entryStore.save(targetEntry)
    }

    public func importVideo(from sourceURL: URL, for type: EntryType) async {
        do {
            try await importVideoNow(from: sourceURL, for: type, targetDay: dayKey)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func importVideoNow(from sourceURL: URL, for type: EntryType, targetDay: LocalDayKey) async throws {
        if targetDay == dayKey {
            let ref = try await environment.entryStore.importVideo(from: sourceURL, day: dayKey, type: type)
            var item = entry.item(for: type)
            item.videos.append(ref)
            item.updatedAt = .now
            entry.setItem(item, for: type)
            entry.updatedAt = .now
            try await saveNow()
            return
        }

        var targetEntry = try await environment.entryStore.load(day: targetDay)
        let ref = try await environment.entryStore.importVideo(from: sourceURL, day: targetDay, type: type)
        var item = targetEntry.item(for: type)
        item.videos.append(ref)
        item.updatedAt = .now
        targetEntry.setItem(item, for: type)
        targetEntry.updatedAt = .now
        try await environment.entryStore.save(targetEntry)
    }

    public func removeVideo(_ ref: VideoRef, for type: EntryType) async {
        do {
            try await environment.entryStore.removeVideo(ref, day: dayKey)
            var item = entry.item(for: type)
            item.videos.removeAll { $0.id == ref.id }
            item.updatedAt = .now
            entry.setItem(item, for: type)
            entry.updatedAt = .now
            try await saveNow()
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
            try await saveNow()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func photoURL(for ref: PhotoRef) -> URL {
        environment.photoURL(for: ref, day: dayKey)
    }

    public func videoURL(for ref: VideoRef) -> URL {
        environment.videoURL(for: ref, day: dayKey)
    }

    public func bindingText(for type: EntryType) -> String {
        entry.item(for: type).shortText
    }

    public func bindingJournal(for type: EntryType) -> String {
        entry.item(for: type).journalTextMarkdown
    }

    public func photos(for type: EntryType) -> [PhotoRef] {
        entry.item(for: type).photos
    }

    public func videos(for type: EntryType) -> [VideoRef] {
        entry.item(for: type).videos
    }

    public func toggleExpanded(_ type: EntryType) {
        if expandedTypes.contains(type) {
            expandedTypes.remove(type)
        } else {
            expandedTypes.insert(type)
        }
    }

    public func isExpanded(_ type: EntryType) -> Bool {
        expandedTypes.contains(type)
    }

    public func saveNow() async throws {
        saveTask?.cancel()
        isSaving = true
        defer { isSaving = false }
        try await environment.entryStore.save(entry)
        lastSavedAt = .now
    }

    private func scheduleAutosave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard let self else { return }
            do {
                try await self.saveNow()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
