import Foundation
import Observation
import CoreModels

@MainActor
@Observable
public final class JournalViewModel {
    public private(set) var todayEntry: EntryDay
    public private(set) var timelineDays: [EntryDaySummary] = []
    public private(set) var mode: JournalMode = .timeline
    public private(set) var filters = JournalFilters()

    public var searchQuery = ""

    public private(set) var isLoading = false
    public private(set) var isLoadingMore = false
    public private(set) var hasMoreDays = false
    public private(set) var todayMatchesSearch = false
    public var errorMessage: String?

    public private(set) var isSavingToday = false
    public private(set) var lastSavedAt: Date?

    public let environment: AppEnvironment
    private let dataSource: JournalDataSource
    private let nowProvider: @Sendable () -> Date
    private let debounceDuration: Duration
    private let pageSize: Int
    private let loadBatchSize = 18

    private var sourceDayKeys: [LocalDayKey] = []
    private var sourceCursor = 0

    private var refreshTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var activeRefreshID = UUID()

    public init(
        environment: AppEnvironment,
        nowProvider: @escaping @Sendable () -> Date = { .now },
        debounceDuration: Duration = .milliseconds(300),
        pageSize: Int = 45,
        dataSource: JournalDataSource? = nil
    ) {
        self.environment = environment
        self.nowProvider = nowProvider
        self.debounceDuration = debounceDuration
        self.pageSize = pageSize
        self.dataSource = dataSource ?? JournalDataSource(environment: environment, nowProvider: nowProvider)

        let initialDayKey = environment.dayCalculator.dayKey(for: nowProvider(), timeZone: .current)
        self.todayEntry = EntryDay.empty(dayKey: initialDayKey, now: nowProvider())
    }

    public var todayDayKey: LocalDayKey {
        todayEntry.dayKey
    }

    public var searchResultsAreEmpty: Bool {
        mode == .search && !todayMatchesSearch && timelineDays.isEmpty && !isLoading
    }

    public var todayCompletionCount: Int {
        todayEntry.completionCount
    }

    public var todayHasAnyContent: Bool {
        todayEntry.roseItem.hasAnyContent || todayEntry.budItem.hasAnyContent || todayEntry.thornItem.hasAnyContent
    }

    public var todaySaveFeedbackState: JournalSaveFeedbackState {
        if isSavingToday {
            return .saving
        }

        if todayEntry.isCompleteForDailyCapture {
            return .complete(lastSavedAt)
        }

        if let lastSavedAt, todayHasAnyContent {
            return .saved(lastSavedAt)
        }

        return .draft
    }

    public func load() async {
        await refreshTimeline(debounced: false, invalidateCache: false)
    }

    public func reloadFromExternalChange() async {
        await refreshTimeline(debounced: false, invalidateCache: true)
    }

    public func handleSearchQueryChange(_ text: String) {
        searchQuery = text
        scheduleRefresh(debounced: true)
    }

    public func clearSearch() {
        searchQuery = ""
        scheduleRefresh(debounced: false)
    }

    public func setCategory(_ category: JournalCategoryFilter) {
        guard filters.category != category else { return }
        filters.category = category
        scheduleRefresh(debounced: false)
    }

    public func setHasPhotoOnly(_ isEnabled: Bool) {
        guard filters.hasPhotoOnly != isEnabled else { return }
        filters.hasPhotoOnly = isEnabled
        scheduleRefresh(debounced: false)
    }

    public func loadMoreIfNeeded(currentDayKey: LocalDayKey?) async {
        guard hasMoreDays, !isLoadingMore, !isLoading else { return }

        if let currentDayKey {
            let threshold = max(timelineDays.count - 6, 0)
            let tail = timelineDays.suffix(from: threshold)
            guard tail.contains(where: { $0.dayKey == currentDayKey }) else {
                return
            }
        }

        await appendNextPage(for: activeRefreshID)
    }

    public func updateTodayShortText(_ text: String, for type: EntryType) {
        var item = todayEntry.item(for: type)
        item.shortText = text
        item.updatedAt = nowProvider()
        todayEntry.setItem(item, for: type)
        todayEntry.updatedAt = nowProvider()
        updateTodaySearchMatchIfNeeded()
        scheduleTodayAutosave()
    }

    public func updateTodayJournalText(_ text: String, for type: EntryType) {
        var item = todayEntry.item(for: type)
        item.journalTextMarkdown = text
        item.updatedAt = nowProvider()
        todayEntry.setItem(item, for: type)
        todayEntry.updatedAt = nowProvider()
        updateTodaySearchMatchIfNeeded()
        scheduleTodayAutosave()
    }

    public func importPhoto(
        from sourceURL: URL,
        for type: EntryType,
        targetDay: LocalDayKey
    ) async {
        do {
            if targetDay == todayEntry.dayKey {
                let ref = try await dataSource.importPhoto(from: sourceURL, dayKey: targetDay, type: type)
                var item = todayEntry.item(for: type)
                item.photos.append(ref)
                item.updatedAt = nowProvider()
                todayEntry.setItem(item, for: type)
                todayEntry.updatedAt = nowProvider()
                await saveTodayNow()
                return
            }

            var targetEntry = try await dataSource.loadEntry(dayKey: targetDay)
            let ref = try await dataSource.importPhoto(from: sourceURL, dayKey: targetDay, type: type)
            var item = targetEntry.item(for: type)
            item.photos.append(ref)
            item.updatedAt = nowProvider()
            targetEntry.setItem(item, for: type)
            targetEntry.updatedAt = nowProvider()
            try await dataSource.saveEntry(targetEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func importVideo(
        from sourceURL: URL,
        for type: EntryType,
        targetDay: LocalDayKey
    ) async {
        do {
            if targetDay == todayEntry.dayKey {
                let ref = try await dataSource.importVideo(from: sourceURL, dayKey: targetDay, type: type)
                var item = todayEntry.item(for: type)
                item.videos.append(ref)
                item.updatedAt = nowProvider()
                todayEntry.setItem(item, for: type)
                todayEntry.updatedAt = nowProvider()
                await saveTodayNow()
                return
            }

            var targetEntry = try await dataSource.loadEntry(dayKey: targetDay)
            let ref = try await dataSource.importVideo(from: sourceURL, dayKey: targetDay, type: type)
            var item = targetEntry.item(for: type)
            item.videos.append(ref)
            item.updatedAt = nowProvider()
            targetEntry.setItem(item, for: type)
            targetEntry.updatedAt = nowProvider()
            try await dataSource.saveEntry(targetEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func removeTodayPhoto(_ ref: PhotoRef, for type: EntryType) async {
        do {
            try await dataSource.removePhoto(ref, dayKey: todayEntry.dayKey)
            var item = todayEntry.item(for: type)
            item.photos.removeAll { $0.id == ref.id }
            item.updatedAt = nowProvider()
            todayEntry.setItem(item, for: type)
            todayEntry.updatedAt = nowProvider()
            await saveTodayNow()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func removeTodayVideo(_ ref: VideoRef, for type: EntryType) async {
        do {
            try await dataSource.removeVideo(ref, dayKey: todayEntry.dayKey)
            var item = todayEntry.item(for: type)
            item.videos.removeAll { $0.id == ref.id }
            item.updatedAt = nowProvider()
            todayEntry.setItem(item, for: type)
            todayEntry.updatedAt = nowProvider()
            await saveTodayNow()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func photoURL(for ref: PhotoRef, day: LocalDayKey) -> URL {
        environment.photoURL(for: ref, day: day)
    }

    public func videoURL(for ref: VideoRef, day: LocalDayKey) -> URL {
        environment.videoURL(for: ref, day: day)
    }

    public func saveTodayNow() async {
        saveTask?.cancel()

        isSavingToday = true
        defer { isSavingToday = false }

        do {
            try await dataSource.saveToday(todayEntry)
            lastSavedAt = nowProvider()
            updateTodaySearchMatchIfNeeded()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleTodayAutosave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await self.saveTodayNow()
        }
    }

    private func scheduleRefresh(debounced: Bool) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }
            if debounced {
                try? await Task.sleep(for: self.debounceDuration)
                guard !Task.isCancelled else { return }
            }
            await self.refreshTimeline(debounced: false, invalidateCache: false)
        }
    }

    private func refreshTimeline(debounced: Bool, invalidateCache: Bool) async {
        if debounced {
            scheduleRefresh(debounced: true)
            return
        }

        let refreshID = UUID()
        activeRefreshID = refreshID
        isLoading = true
        isLoadingMore = false

        if invalidateCache {
            await dataSource.invalidateDayCache()
        }

        do {
            let loadedToday = try await dataSource.loadToday()
            guard isCurrent(refreshID) else { return }

            todayEntry = loadedToday
            updateMode()
            updateTodaySearchMatchIfNeeded()

            if mode == .timeline {
                sourceDayKeys = try await dataSource.allPastDayKeys(excluding: loadedToday.dayKey)
            } else {
                sourceDayKeys = try await buildSearchSourceDayKeys(excluding: loadedToday.dayKey)
            }

            guard isCurrent(refreshID) else { return }
            sourceCursor = 0
            timelineDays = []
            hasMoreDays = false
            errorMessage = nil
            await appendNextPage(for: refreshID)
        } catch {
            guard isCurrent(refreshID) else { return }
            timelineDays = []
            sourceDayKeys = []
            sourceCursor = 0
            hasMoreDays = false
            errorMessage = error.localizedDescription
        }

        guard isCurrent(refreshID) else { return }
        isLoading = false
    }

    private func buildSearchSourceDayKeys(excluding todayKey: LocalDayKey) async throws -> [LocalDayKey] {
        let queryText = normalizedQueryText
        let categories = filters.category.entryTypes
        let hasPhotoFilter = filters.hasPhotoOnly ? true : nil

        let query = EntrySearchQuery(
            text: queryText,
            categories: categories,
            hasPhoto: hasPhotoFilter,
            dateRange: nil
        )

        let results: [LocalDayKey]
        do {
            results = try await dataSource.search(query: query)
        } catch {
            results = try await dataSource.fallbackSearch(
                text: queryText,
                categories: categories,
                hasPhoto: hasPhotoFilter
            )
        }

        return results.filter { $0 != todayKey }
    }

    private func appendNextPage(for refreshID: UUID) async {
        guard isCurrent(refreshID) else { return }
        guard !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        var page: [EntryDaySummary] = []
        page.reserveCapacity(pageSize)

        while page.count < pageSize && sourceCursor < sourceDayKeys.count {
            guard isCurrent(refreshID) else { return }

            let batchEnd = min(sourceCursor + loadBatchSize, sourceDayKeys.count)
            let batchKeys = Array(sourceDayKeys[sourceCursor..<batchEnd])
            let pairs = await dataSource.loadSummaryPairs(for: batchKeys)
            var consumedCount = 0

            for pair in pairs {
                consumedCount += 1
                guard let summary = pair.summary else { continue }
                guard summaryMatchesCurrentFilters(summary) else { continue }

                page.append(summary)
                if page.count >= pageSize {
                    break
                }
            }

            sourceCursor += consumedCount
        }

        guard isCurrent(refreshID) else { return }
        timelineDays.append(contentsOf: page)
        hasMoreDays = sourceCursor < sourceDayKeys.count
    }

    private func summaryMatchesCurrentFilters(_ summary: EntryDaySummary) -> Bool {
        if filters.hasPhotoOnly && !summary.hasMedia {
            return false
        }

        let lines = summary.lines(for: filters.category)

        switch filters.category {
        case .all:
            return !lines.isEmpty || summary.hasMedia
        case .rose:
            return !summary.roseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || summary.roseHasMedia
        case .bud:
            return !summary.budText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || summary.budHasMedia
        case .thorn:
            return !summary.thornText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || summary.thornHasMedia
        }
    }

    private func updateMode() {
        mode = normalizedQueryText.isEmpty ? .timeline : .search
    }

    private func updateTodaySearchMatchIfNeeded() {
        if mode == .search {
            todayMatchesSearch = todayMatchesCurrentCriteria()
        } else {
            todayMatchesSearch = false
        }
    }

    private func todayMatchesCurrentCriteria() -> Bool {
        if filters.hasPhotoOnly && !todayEntry.hasAnyPhotos {
            return false
        }

        let categories = filters.category.entryTypes
        let query = normalizedQueryText
        guard !query.isEmpty else { return false }

        return categories.contains { type in
            todayEntry.item(for: type).combinedText.lowercased().contains(query)
        }
    }

    private var normalizedQueryText: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isCurrent(_ refreshID: UUID) -> Bool {
        activeRefreshID == refreshID
    }
}
