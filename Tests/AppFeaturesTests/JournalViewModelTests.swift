import XCTest
@testable import AppFeatures
@testable import DocumentStore
@testable import CoreModels
@testable import CoreDate

@MainActor
final class JournalViewModelTests: XCTestCase {
    private func makeEnvironment() throws -> AppEnvironment {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return try AppEnvironment(configuration: DocumentStoreConfiguration(rootURL: root))
    }

    private func makeEntry(
        dayKey: LocalDayKey,
        rose: String = "",
        bud: String = "",
        thorn: String = "",
        favorite: Bool = false,
        includePhoto: Bool = false
    ) -> EntryDay {
        let photo: [PhotoRef] = includePhoto
            ? [PhotoRef(id: UUID(), relativePath: "rose/attachments/photo.jpg", createdAt: .now)]
            : []

        return EntryDay(
            dayKey: dayKey,
            roseItem: EntryItem(type: .rose, shortText: rose, journalTextMarkdown: "", photos: photo, updatedAt: .now),
            budItem: EntryItem(type: .bud, shortText: bud, journalTextMarkdown: "", updatedAt: .now),
            thornItem: EntryItem(type: .thorn, shortText: thorn, journalTextMarkdown: "", updatedAt: .now),
            favorite: favorite,
            createdAt: .now,
            updatedAt: .now
        )
    }

    func testPaginationLoadsNextPagesAndStopsAtEnd() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600) // 2026-03-05
        let dayCalculator = DayKeyCalculator()

        let today = dayCalculator.dayKey(for: now, timeZone: .current)
        try await environment.entryStore.save(makeEntry(dayKey: today, rose: "Today"))

        let pastKeys = (1...5).map { offset in
            dayCalculator.dayKey(for: now.addingTimeInterval(TimeInterval(-86_400 * offset)), timeZone: .current)
        }

        for key in pastKeys {
            try await environment.entryStore.save(makeEntry(dayKey: key, rose: "Past \(key.isoDate)"))
        }

        let model = JournalViewModel(
            environment: environment,
            nowProvider: { now },
            debounceDuration: .milliseconds(10),
            pageSize: 2
        )

        await model.load()
        XCTAssertEqual(model.timelineDays.count, 2)
        XCTAssertTrue(model.hasMoreDays)

        if let last = model.timelineDays.last?.dayKey {
            await model.loadMoreIfNeeded(currentDayKey: last)
        }
        await waitUntil { model.timelineDays.count == 4 }

        if let last = model.timelineDays.last?.dayKey {
            await model.loadMoreIfNeeded(currentDayKey: last)
        }
        await waitUntil { model.timelineDays.count == 5 }

        XCTAssertFalse(model.hasMoreDays)
    }

    func testFilteringByCategoryPhotoAndFavorites() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600)
        let dayCalculator = DayKeyCalculator()

        let today = dayCalculator.dayKey(for: now, timeZone: .current)
        let dayA = dayCalculator.dayKey(for: now.addingTimeInterval(-86_400), timeZone: .current)
        let dayB = dayCalculator.dayKey(for: now.addingTimeInterval(-172_800), timeZone: .current)
        let dayC = dayCalculator.dayKey(for: now.addingTimeInterval(-259_200), timeZone: .current)

        try await environment.entryStore.save(makeEntry(dayKey: today, rose: "Today"))
        try await environment.entryStore.save(makeEntry(dayKey: dayA, rose: "Rose only"))
        try await environment.entryStore.save(makeEntry(dayKey: dayB, bud: "Bud only"))
        try await environment.entryStore.save(makeEntry(dayKey: dayC, rose: "Rose media", favorite: true, includePhoto: true))

        let model = JournalViewModel(environment: environment, nowProvider: { now }, debounceDuration: .milliseconds(10), pageSize: 45)
        await model.load()

        model.setCategory(.rose)
        await waitUntil { model.timelineDays.count == 2 }
        XCTAssertTrue(model.timelineDays.allSatisfy { !$0.roseText.isEmpty || $0.roseHasMedia })

        model.setHasPhotoOnly(true)
        await waitUntil { model.timelineDays.count == 1 }
        XCTAssertTrue(model.timelineDays.first?.hasMedia ?? false)

        model.setFavoritesOnly(true)
        await waitUntil { model.timelineDays.count == 1 }
        XCTAssertTrue(model.timelineDays.first?.favorite ?? false)
    }

    func testDebouncedSearchUsesLatestQuery() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600)
        let dayCalculator = DayKeyCalculator()

        let today = dayCalculator.dayKey(for: now, timeZone: .current)
        let dayA = dayCalculator.dayKey(for: now.addingTimeInterval(-86_400), timeZone: .current)
        let dayB = dayCalculator.dayKey(for: now.addingTimeInterval(-172_800), timeZone: .current)

        try await environment.entryStore.save(makeEntry(dayKey: today, rose: "today content"))
        try await environment.entryStore.save(makeEntry(dayKey: dayA, rose: "alpha entry"))
        try await environment.entryStore.save(makeEntry(dayKey: dayB, rose: "final target"))

        let model = JournalViewModel(environment: environment, nowProvider: { now }, debounceDuration: .milliseconds(25), pageSize: 45)
        await model.load()

        model.handleSearchQueryChange("al")
        model.handleSearchQueryChange("alpha")
        model.handleSearchQueryChange("target")

        await waitUntil {
            model.mode == .search &&
            model.timelineDays.count == 1 &&
            model.timelineDays.first?.dayKey == dayB
        }

        XCTAssertEqual(model.searchQuery, "target")
    }

    func testTodayEditUpdatesUpdatedAtAndAutosaves() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, debounceDuration: .milliseconds(10), pageSize: 45)

        await model.load()
        let previousUpdatedAt = model.todayEntry.updatedAt

        model.updateTodayShortText("Autosave from Journal", for: .rose)
        XCTAssertGreaterThanOrEqual(model.todayEntry.updatedAt, previousUpdatedAt)

        let deadline = Date().addingTimeInterval(2)
        var persistedText = ""

        while Date() < deadline {
            let persisted = try await environment.entryStore.load(day: model.todayDayKey)
            persistedText = persisted.roseItem.shortText
            if persistedText == "Autosave from Journal" {
                break
            }
            try? await Task.sleep(for: .milliseconds(60))
        }

        XCTAssertEqual(persistedText, "Autosave from Journal")
    }

    func testTodayMatchesSearchWhenQueryHitsTodayText() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600)
        let dayCalculator = DayKeyCalculator()
        let today = dayCalculator.dayKey(for: now, timeZone: .current)

        try await environment.entryStore.save(makeEntry(dayKey: today, rose: "coffee and sun"))

        let model = JournalViewModel(environment: environment, nowProvider: { now }, debounceDuration: .milliseconds(20), pageSize: 45)
        await model.load()

        model.handleSearchQueryChange("coffee")
        await waitUntil { model.mode == .search && model.todayMatchesSearch }

        model.handleSearchQueryChange("nomatch")
        await waitUntil { model.mode == .search && !model.todayMatchesSearch }
    }

    func testTodaySaveFeedbackTransitionsFromDraftToSavedToComplete() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, debounceDuration: .milliseconds(10), pageSize: 20)

        await model.load()
        XCTAssertEqual(model.todaySaveFeedbackState, .draft)

        model.updateTodayShortText("Morning walk", for: .rose)
        await waitUntil {
            if case .saved = model.todaySaveFeedbackState { return true }
            return false
        }

        model.updateTodayShortText("Project idea", for: .bud)
        model.updateTodayShortText("Traffic", for: .thorn)
        await waitUntil {
            if case .complete = model.todaySaveFeedbackState { return true }
            return false
        }
    }

    func testRemoveTodayPhotoClearsMediaFromEntry() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, debounceDuration: .milliseconds(10), pageSize: 20)
        await model.load()

        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        let jpegBytes = Data([0xFF, 0xD8, 0xFF, 0xD9])
        try jpegBytes.write(to: temporaryURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        await model.importPhoto(from: temporaryURL, for: .rose, targetDay: model.todayDayKey)
        await waitUntil { !model.todayEntry.roseItem.photos.isEmpty }

        guard let ref = model.todayEntry.roseItem.photos.first else {
            XCTFail("Expected imported photo.")
            return
        }

        await model.removeTodayPhoto(ref, for: .rose)
        await waitUntil { model.todayEntry.roseItem.photos.isEmpty }

        let persisted = try await environment.entryStore.load(day: model.todayDayKey)
        XCTAssertTrue(persisted.roseItem.photos.isEmpty)
    }

    private func waitUntil(
        timeout: TimeInterval = 2.0,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if condition() {
                return
            }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}
