import Foundation
import CoreModels
import CoreDate

public actor JournalDataSource {
    private let environment: AppEnvironment
    private let dayCalculator: DayKeyCalculator
    private let nowProvider: @Sendable () -> Date

    private var cachedDayKeys: [LocalDayKey]?
    private var cachedDayKeySet: Set<LocalDayKey> = []

    public init(
        environment: AppEnvironment,
        nowProvider: @escaping @Sendable () -> Date = { .now }
    ) {
        self.environment = environment
        self.dayCalculator = environment.dayCalculator
        self.nowProvider = nowProvider
    }

    public func todayKey() -> LocalDayKey {
        dayCalculator.dayKey(for: nowProvider(), timeZone: .current)
    }

    public func loadToday() async throws -> EntryDay {
        try await environment.entryStore.load(day: todayKey())
    }

    public func saveToday(_ entry: EntryDay) async throws {
        try await environment.entryStore.save(entry)
        upsertDayKey(entry.dayKey)
    }

    public func saveEntry(_ entry: EntryDay) async throws {
        try await environment.entryStore.save(entry)
        upsertDayKey(entry.dayKey)
    }

    public func importPhoto(from sourceURL: URL, dayKey: LocalDayKey, type: EntryType) async throws -> PhotoRef {
        let ref = try await environment.entryStore.importPhoto(from: sourceURL, day: dayKey, type: type)
        upsertDayKey(dayKey)
        return ref
    }

    public func importVideo(from sourceURL: URL, dayKey: LocalDayKey, type: EntryType) async throws -> VideoRef {
        let ref = try await environment.entryStore.importVideo(from: sourceURL, day: dayKey, type: type)
        upsertDayKey(dayKey)
        return ref
    }

    public func removePhoto(_ ref: PhotoRef, dayKey: LocalDayKey) async throws {
        try await environment.entryStore.removePhoto(ref, day: dayKey)
    }

    public func removeVideo(_ ref: VideoRef, dayKey: LocalDayKey) async throws {
        try await environment.entryStore.removeVideo(ref, day: dayKey)
    }

    public func allPastDayKeys(excluding dayKey: LocalDayKey) async throws -> [LocalDayKey] {
        try await allDayKeys().filter { $0 != dayKey }
    }

    public func search(query: EntrySearchQuery) async throws -> [LocalDayKey] {
        try await environment.entryStore.search(query)
    }

    public func fallbackSearch(
        text: String,
        categories: Set<EntryType>,
        hasPhoto: Bool?
    ) async throws -> [LocalDayKey] {
        let keys = try await allDayKeys()
        var results: [LocalDayKey] = []
        results.reserveCapacity(keys.count)

        for dayKey in keys {
            let entry = try await loadEntry(dayKey: dayKey)

            if entryMatches(
                entry,
                text: text,
                categories: categories,
                hasPhoto: hasPhoto
            ) {
                results.append(dayKey)
            }
        }

        return results.sorted(by: >)
    }

    public func loadSummaries(for dayKeys: [LocalDayKey]) async -> [EntryDaySummary] {
        await loadSummaryPairs(for: dayKeys).compactMap { $0.summary }
    }

    func loadSummaryPairs(for dayKeys: [LocalDayKey]) async -> [(dayKey: LocalDayKey, summary: EntryDaySummary?)] {
        guard !dayKeys.isEmpty else { return [] }

        return await withTaskGroup(of: (Int, EntryDaySummary?).self) { group in
            for (index, dayKey) in dayKeys.enumerated() {
                group.addTask { [weak self] in
                    guard let self else { return (index, nil) }
                    guard let entry = try? await self.loadEntry(dayKey: dayKey) else {
                        return (index, nil)
                    }
                    return (index, EntryDaySummary(entry: entry))
                }
            }

            var ordered: [EntryDaySummary?] = Array(repeating: nil, count: dayKeys.count)
            for await (index, summary) in group {
                ordered[index] = summary
            }

            return ordered.enumerated().map { index, summary in
                (dayKey: dayKeys[index], summary: summary)
            }
        }
    }

    public func loadSummary(dayKey: LocalDayKey) async -> EntryDaySummary? {
        guard let entry = try? await loadEntry(dayKey: dayKey) else {
            return nil
        }
        return EntryDaySummary(entry: entry)
    }

    public func loadEntry(dayKey: LocalDayKey) async throws -> EntryDay {
        try await environment.entryStore.load(day: dayKey)
    }

    public func photoURL(for ref: PhotoRef, day: LocalDayKey) -> URL {
        environment.photoURL(for: ref, day: day)
    }

    public func videoURL(for ref: VideoRef, day: LocalDayKey) -> URL {
        environment.videoURL(for: ref, day: day)
    }

    public func invalidateDayCache() {
        cachedDayKeys = nil
        cachedDayKeySet = []
    }

    private func allDayKeys() async throws -> [LocalDayKey] {
        if let cachedDayKeys {
            return cachedDayKeys
        }

        let days = try await environment.entryStore.list(range: nil)
        cachedDayKeys = days
        cachedDayKeySet = Set(days)
        return days
    }

    private func upsertDayKey(_ dayKey: LocalDayKey) {
        guard !cachedDayKeySet.contains(dayKey) else { return }
        cachedDayKeySet.insert(dayKey)

        guard var cachedDayKeys else { return }
        cachedDayKeys.append(dayKey)
        cachedDayKeys.sort(by: >)
        self.cachedDayKeys = cachedDayKeys
    }

    private func entryMatches(
        _ entry: EntryDay,
        text: String,
        categories: Set<EntryType>,
        hasPhoto: Bool?
    ) -> Bool {
        if let hasPhoto {
            if hasPhoto && !entry.hasAnyPhotos { return false }
            if !hasPhoto && entry.hasAnyPhotos { return false }
        }

        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let activeCategories = categories.isEmpty ? Set(EntryType.allCases) : categories

        if normalizedText.isEmpty {
            return hasAnyContent(in: entry, categories: activeCategories)
        }

        return activeCategories.contains { type in
            entry.item(for: type).combinedText.lowercased().contains(normalizedText)
        }
    }

    private func hasAnyContent(in entry: EntryDay, categories: Set<EntryType>) -> Bool {
        categories.contains { type in
            let item = entry.item(for: type)
            return !item.shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
