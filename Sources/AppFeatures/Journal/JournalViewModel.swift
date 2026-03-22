import Foundation
import Observation
import CoreModels

@MainActor
@Observable
public final class JournalViewModel {
    public private(set) var todayEntry: EntryDay
    public private(set) var timelineDays: [EntryDaySummary] = []
    public private(set) var promptSelections: [EntryType: PromptSelection] = [:]
    public private(set) var activeCaptureType: EntryType = .rose

    public private(set) var isLoading = false
    public private(set) var isLoadingMore = false
    public private(set) var hasMoreDays = false
    public var errorMessage: String?

    public private(set) var isSavingToday = false
    public private(set) var lastSavedAt: Date?
    public private(set) var os26UIEnabled = true
    public private(set) var isCaptureFlowFinalized = false

    public let environment: AppEnvironment
    private let dataSource: JournalDataSource
    private let nowProvider: @Sendable () -> Date
    private let pageSize: Int
    private let loadBatchSize = 18

    private var sourceDayKeys: [LocalDayKey] = []
    private var sourceCursor = 0

    private var saveTask: Task<Void, Never>?
    private var activeRefreshID = UUID()

    public init(
        environment: AppEnvironment,
        nowProvider: @escaping @Sendable () -> Date = { .now },
        pageSize: Int = 45,
        dataSource: JournalDataSource? = nil
    ) {
        self.environment = environment
        self.nowProvider = nowProvider
        self.pageSize = pageSize
        self.dataSource = dataSource ?? JournalDataSource(environment: environment, nowProvider: nowProvider)

        let initialDayKey = environment.dayCalculator.dayKey(for: nowProvider(), timeZone: .current)
        self.todayEntry = EntryDay.empty(dayKey: initialDayKey, now: nowProvider())
    }

    public var todayDayKey: LocalDayKey {
        todayEntry.dayKey
    }

    public var todayCompletionCount: Int {
        todayEntry.completionCount
    }

    public var todayHasAnyContent: Bool {
        todayEntry.roseItem.hasAnyContent || todayEntry.budItem.hasAnyContent || todayEntry.thornItem.hasAnyContent
    }

    public var activePromptSelection: PromptSelection? {
        promptSelections[activeCaptureType]
    }

    public var canContinueActiveCapture: Bool {
        todayEntry.item(for: activeCaptureType).hasAnyContent
    }

    public var continueButtonTitle: String {
        isFinalContinueAction ? "Done" : "Continue"
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
        await refreshTimeline(invalidateCache: false)
    }

    public func reloadFromExternalChange() async {
        await refreshTimeline(invalidateCache: true)
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

    public func setActiveCaptureType(_ type: EntryType) {
        activeCaptureType = type
    }

    @discardableResult
    public func continueToNextIncompleteCaptureStep() -> Bool {
        guard canContinueActiveCapture else { return false }
        if let nextType = firstIncompleteType() {
            activeCaptureType = nextType
            return true
        }

        guard todayEntry.isCompleteForDailyCapture else { return false }
        isCaptureFlowFinalized = true
        Task {
            await saveTodayNow()
        }

        return true
    }

    public func updateTodayShortText(_ text: String, for type: EntryType) {
        var item = todayEntry.item(for: type)
        item.shortText = text
        item.updatedAt = nowProvider()
        todayEntry.setItem(item, for: type)
        todayEntry.updatedAt = nowProvider()
        if !todayEntry.isCompleteForDailyCapture {
            isCaptureFlowFinalized = false
        }
        scheduleTodayAutosave()
    }

    public func updateTodayJournalText(_ text: String, for type: EntryType) {
        var item = todayEntry.item(for: type)
        item.journalTextMarkdown = text
        item.updatedAt = nowProvider()
        todayEntry.setItem(item, for: type)
        todayEntry.updatedAt = nowProvider()
        if !todayEntry.isCompleteForDailyCapture {
            isCaptureFlowFinalized = false
        }
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
                if !todayEntry.isCompleteForDailyCapture {
                    isCaptureFlowFinalized = false
                }
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
                if !todayEntry.isCompleteForDailyCapture {
                    isCaptureFlowFinalized = false
                }
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
            if !todayEntry.isCompleteForDailyCapture {
                isCaptureFlowFinalized = false
            }
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
            if !todayEntry.isCompleteForDailyCapture {
                isCaptureFlowFinalized = false
            }
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
            errorMessage = nil
            WidgetSnapshotSync.syncTodayEntry(
                todayEntry,
                dayDirectoryURL: environment.dayDirectoryURL(for: todayEntry.dayKey),
                widgetsEnabled: featureFlags.widgetsEnabled
            )
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

    private func refreshTimeline(invalidateCache: Bool) async {
        let refreshID = UUID()
        activeRefreshID = refreshID
        isLoading = true
        isLoadingMore = false
        os26UIEnabled = featureFlags.os26UIEnabled

        if invalidateCache {
            await dataSource.invalidateDayCache()
        }

        do {
            let loadedToday = try await dataSource.loadToday()
            guard isCurrent(refreshID) else { return }

            todayEntry = loadedToday
            refreshPromptSelections(for: loadedToday.dayKey)
            resetActiveCaptureType()
            isCaptureFlowFinalized = loadedToday.isCompleteForDailyCapture
            WidgetSnapshotSync.syncTodayEntry(
                todayEntry,
                dayDirectoryURL: environment.dayDirectoryURL(for: todayEntry.dayKey),
                widgetsEnabled: featureFlags.widgetsEnabled
            )
            sourceDayKeys = try await dataSource.allPastDayKeys(excluding: loadedToday.dayKey)

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
            promptSelections = [:]
            activeCaptureType = .rose
            isCaptureFlowFinalized = false
            errorMessage = error.localizedDescription
        }

        guard isCurrent(refreshID) else { return }
        isLoading = false
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

    private func isCurrent(_ refreshID: UUID) -> Bool {
        activeRefreshID == refreshID
    }

    private func refreshPromptSelections(for dayKey: LocalDayKey) {
        let preferences = environment.promptPreferencesStore.load()
        promptSelections = environment.promptSelector.prompts(for: dayKey, preferences: preferences)
    }

    private func resetActiveCaptureType() {
        if let firstIncomplete = firstIncompleteType() {
            activeCaptureType = firstIncomplete
            return
        }
        activeCaptureType = EntryType.allCases.last ?? .thorn
    }

    private func firstIncompleteType() -> EntryType? {
        EntryType.allCases.first(where: { !todayEntry.item(for: $0).hasAnyContent })
    }

    private var isFinalContinueAction: Bool {
        canContinueActiveCapture && firstIncompleteType() == nil
    }

    private var featureFlags: AppFeatureFlags {
        environment.featureFlagStore.load(defaults: environment.featureFlags)
    }
}
