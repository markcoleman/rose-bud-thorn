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

    func testTodayEditUpdatesUpdatedAtAndAutosaves() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, pageSize: 45)

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

    func testTodaySaveFeedbackTransitionsFromDraftToSavedToComplete() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, pageSize: 20)

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
        let model = JournalViewModel(environment: environment, pageSize: 20)
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

    func testActiveCaptureTypeDefaultsToFirstIncompleteOnLoad() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600) // 2026-03-05
        let dayKey = DayKeyCalculator().dayKey(for: now, timeZone: .current)
        try await environment.entryStore.save(makeEntry(dayKey: dayKey, rose: "Completed rose"))

        let model = JournalViewModel(environment: environment, nowProvider: { now }, pageSize: 20)
        await model.load()

        XCTAssertEqual(model.activeCaptureType, .bud)
    }

    func testActiveCaptureTypeDefaultsToLastTypeWhenComplete() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600) // 2026-03-05
        let dayKey = DayKeyCalculator().dayKey(for: now, timeZone: .current)
        try await environment.entryStore.save(
            makeEntry(
                dayKey: dayKey,
                rose: "Done",
                bud: "Done",
                thorn: "Done"
            )
        )

        let model = JournalViewModel(environment: environment, nowProvider: { now }, pageSize: 20)
        await model.load()

        XCTAssertEqual(model.activeCaptureType, .thorn)
    }

    func testContinueAdvancesToNextIncompleteType() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, pageSize: 20)
        await model.load()

        XCTAssertEqual(model.activeCaptureType, .rose)
        XCTAssertFalse(model.continueToNextIncompleteCaptureStep())

        model.updateTodayShortText("Rose complete", for: .rose)
        XCTAssertTrue(model.continueToNextIncompleteCaptureStep())
        XCTAssertEqual(model.activeCaptureType, .bud)

        model.updateTodayShortText("Bud complete", for: .bud)
        XCTAssertTrue(model.continueToNextIncompleteCaptureStep())
        XCTAssertEqual(model.activeCaptureType, .thorn)
    }

    func testContinueAdvancesToFirstIncompleteWhenViewingDifferentPill() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, pageSize: 20)
        await model.load()

        model.updateTodayShortText("Rose complete", for: .rose)
        model.setActiveCaptureType(.thorn)
        model.updateTodayShortText("Thorn complete", for: .thorn)

        XCTAssertEqual(model.continueButtonTitle, "Continue")
        XCTAssertTrue(model.continueToNextIncompleteCaptureStep())
        XCTAssertEqual(model.activeCaptureType, .bud)
    }

    func testPromptSelectionLoadsForActiveType() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, pageSize: 20)

        await model.load()

        XCTAssertNotNil(model.activePromptSelection)
    }

    func testSetActiveCaptureTypeUpdatesFocusTarget() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, pageSize: 20)
        await model.load()

        model.setActiveCaptureType(.thorn)

        XCTAssertEqual(model.activeCaptureType, .thorn)
    }

    func testContinueOnFinalStepTriggersCompletionSave() async throws {
        let environment = try makeEnvironment()
        let model = JournalViewModel(environment: environment, pageSize: 20)
        await model.load()

        model.updateTodayShortText("Rose", for: .rose)
        model.updateTodayShortText("Bud", for: .bud)
        model.updateTodayShortText("Thorn", for: .thorn)
        model.setActiveCaptureType(.thorn)

        XCTAssertEqual(model.continueButtonTitle, "Done")
        XCTAssertTrue(model.continueToNextIncompleteCaptureStep())
        XCTAssertTrue(model.isCaptureFlowFinalized)
        await waitUntil { model.lastSavedAt != nil }
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
