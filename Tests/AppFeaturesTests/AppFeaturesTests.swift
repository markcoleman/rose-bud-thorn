import XCTest
@testable import AppFeatures
@testable import DocumentStore
@testable import CoreModels
@testable import CoreDate

@MainActor
final class AppFeaturesTests: XCTestCase {
    private func makeEnvironment() throws -> AppEnvironment {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return try AppEnvironment(configuration: DocumentStoreConfiguration(rootURL: root))
    }

    private func makeInMemoryEntryStore() -> EntryStore {
        EntryStore(
            entries: InMemoryEntryRepository(),
            attachments: NoopAttachmentRepository(),
            index: NoopSearchIndex()
        )
    }

    func testTodayCaptureFlowPersistsEntry() async throws {
        let environment = try makeEnvironment()
        let fixedDate = Date(timeIntervalSince1970: 1_772_201_600) // 2026-03-05
        let viewModel = TodayViewModel(environment: environment, now: fixedDate)

        await viewModel.load()
        viewModel.updateShortText("Great coffee", for: .rose)
        viewModel.updateShortText("New project kickoff", for: .bud)
        viewModel.updateJournalText("Commute was rough.", for: .thorn)
        try await viewModel.saveNow()

        let dayKey = viewModel.dayKey
        let persisted = try await environment.entryStore.load(day: dayKey)

        XCTAssertEqual(persisted.roseItem.shortText, "Great coffee")
        XCTAssertEqual(persisted.budItem.shortText, "New project kickoff")
        XCTAssertEqual(persisted.thornItem.journalTextMarkdown, "Commute was rough.")
    }

    func testSearchViewModelFindsSavedEntry() async throws {
        let environment = try makeEnvironment()
        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")

        let entry = EntryDay(
            dayKey: dayKey,
            roseItem: EntryItem(type: .rose, shortText: "sunny bike ride", journalTextMarkdown: "", updatedAt: .now),
            budItem: EntryItem(type: .bud, shortText: "new idea", journalTextMarkdown: "", updatedAt: .now),
            thornItem: EntryItem(type: .thorn, shortText: "slow traffic", journalTextMarkdown: "", updatedAt: .now),
            createdAt: .now,
            updatedAt: .now
        )

        try await environment.entryStore.save(entry)

        let searchVM = SearchViewModel(environment: environment)
        searchVM.queryText = "bike"
        await searchVM.runSearch()

        XCTAssertEqual(searchVM.results, [dayKey])
    }

    func testTodayViewModelImportVideoPersistsEntry() async throws {
        let environment = try makeEnvironment()
        let viewModel = TodayViewModel(environment: environment, now: Date(timeIntervalSince1970: 1_772_201_600))
        await viewModel.load()

        let source = environment.configuration.rootURL.appendingPathComponent("captured.mov")
        try Data("video-bytes".utf8).write(to: source)

        try await viewModel.importVideoNow(from: source, for: .bud, targetDay: viewModel.dayKey)
        let persisted = try await environment.entryStore.load(day: viewModel.dayKey)

        XCTAssertEqual(persisted.budItem.videos.count, 1)
        XCTAssertTrue(persisted.budItem.videos[0].relativePath.contains("bud/attachments"))
    }

    func testCaptureLaunchRequestParserParsesTypedDeepLink() {
        let url = URL(string: "rosebudthorn://capture?source=widget&type=bud")!
        let request = RootAppView.captureLaunchRequest(from: url)

        XCTAssertEqual(request?.type, .bud)
        XCTAssertEqual(request?.source, "widget")
    }

    func testReminderPreferencesPersistAcrossStoreReload() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = ReminderPreferencesStore(defaults: defaults)
        let prefs = ReminderPreferences(
            isEnabled: true,
            startHour: 9,
            endHour: 21,
            includeWeekends: false,
            allowsEndOfDayFallback: true
        )

        store.save(prefs)
        XCTAssertEqual(store.load(), prefs)
    }

    func testCompletionTrackerUpdatesWhenTodayEntrySaved() async throws {
        let dayCalculator = DayKeyCalculator()
        let entryStore = makeInMemoryEntryStore()
        let tracker = EntryCompletionTracker(entryStore: entryStore, dayCalculator: dayCalculator)

        var entry = EntryDay.empty(dayKey: dayCalculator.dayKey(for: .now))
        entry.roseItem.shortText = "Done"
        try await entryStore.save(entry)

        let summary = try await tracker.summary(for: .now, timeZone: .current)
        XCTAssertTrue(summary.isTodayComplete)
        XCTAssertEqual(summary.streakCount, 1)
        XCTAssertEqual(summary.last7DaysCompleted.filter(\.self).count, 1)
    }

    func testCompletionTrackerReturnsEmptySummaryWithoutEntries() async throws {
        let tracker = EntryCompletionTracker(entryStore: makeInMemoryEntryStore(), dayCalculator: DayKeyCalculator())

        let summary = try await tracker.summary(for: Date(timeIntervalSince1970: 1_772_201_600), timeZone: .current)

        XCTAssertFalse(summary.isTodayComplete)
        XCTAssertEqual(summary.streakCount, 0)
        XCTAssertEqual(summary.previousStreakCount, 0)
        XCTAssertEqual(summary.last7DaysCompleted, Array(repeating: false, count: 7))
    }

    func testCompletionTrackerUsesProvidedTimezoneForConsecutiveDays() async throws {
        let dayCalculator = DayKeyCalculator()
        let entryStore = makeInMemoryEntryStore()
        let tracker = EntryCompletionTracker(entryStore: entryStore, dayCalculator: dayCalculator)
        let tz = TimeZone(identifier: "America/Los_Angeles")!

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!

        for offset in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -offset, to: now)!
            let dayKey = dayCalculator.dayKey(for: date, timeZone: tz)
            var entry = EntryDay.empty(dayKey: dayKey)
            entry.budItem.shortText = "Day \(offset)"
            try await entryStore.save(entry)
        }

        let summary = try await tracker.summary(for: now, timeZone: tz)
        XCTAssertTrue(summary.isTodayComplete)
        XCTAssertEqual(summary.streakCount, 3)
        XCTAssertEqual(summary.last7DaysCompleted.filter(\.self).count, 3)
    }

}

private actor InMemoryEntryRepository: EntryRepository {
    private var entries: [LocalDayKey: EntryDay] = [:]

    func load(day: LocalDayKey) async throws -> EntryDay? {
        entries[day]
    }

    func save(_ entry: EntryDay) async throws {
        entries[entry.dayKey] = entry
    }

    func delete(day: LocalDayKey) async throws {
        entries.removeValue(forKey: day)
    }

    func list(range: DateInterval?) async throws -> [LocalDayKey] {
        let dayCalculator = DayKeyCalculator()
        return entries.keys
            .filter { dayKey in
                guard let range else { return true }
                guard let date = dayCalculator.date(for: dayKey) else { return false }
                return range.contains(date)
            }
            .sorted(by: >)
    }
}

private actor NoopAttachmentRepository: AttachmentRepository {
    func importImage(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> PhotoRef {
        PhotoRef(id: UUID(), relativePath: sourceURL.path, createdAt: .now)
    }

    func importVideo(from sourceURL: URL, day: LocalDayKey, type: EntryType) async throws -> VideoRef {
        VideoRef(id: UUID(), relativePath: sourceURL.path, createdAt: .now, durationSeconds: 1, hasAudio: false)
    }

    func remove(_ ref: PhotoRef, day: LocalDayKey) async throws {}

    func removeVideo(_ ref: VideoRef, day: LocalDayKey) async throws {}
}

private actor NoopSearchIndex: SearchIndex {
    func upsert(_ entry: EntryDay) async throws {}
    func remove(day: LocalDayKey) async throws {}
    func search(_ query: EntrySearchQuery) async throws -> [LocalDayKey] { [] }
    func rebuildFromEntries() async throws {}
}
