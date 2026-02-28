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
}
