import XCTest
@testable import AppFeatures
@testable import DocumentStore
@testable import CoreModels
@testable import CoreDate

final class JournalDataSourceTests: XCTestCase {
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
            ? [PhotoRef(id: UUID(), relativePath: "rose/attachments/seed.jpg", createdAt: .now)]
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

    func testAllPastDayKeysExcludeTodayAndRemainDescending() async throws {
        let environment = try makeEnvironment()
        let now = Date(timeIntervalSince1970: 1_772_201_600) // 2026-03-05
        let dayCalculator = DayKeyCalculator()

        let today = dayCalculator.dayKey(for: now, timeZone: .current)
        let yesterday = dayCalculator.dayKey(for: now.addingTimeInterval(-86_400), timeZone: .current)
        let twoDaysAgo = dayCalculator.dayKey(for: now.addingTimeInterval(-172_800), timeZone: .current)

        try await environment.entryStore.save(makeEntry(dayKey: today, rose: "Today"))
        try await environment.entryStore.save(makeEntry(dayKey: yesterday, rose: "Yesterday"))
        try await environment.entryStore.save(makeEntry(dayKey: twoDaysAgo, rose: "Two days"))

        let dataSource = JournalDataSource(environment: environment, nowProvider: { now })
        let keys = try await dataSource.allPastDayKeys(excluding: today)

        XCTAssertEqual(keys, [yesterday, twoDaysAgo])
    }

    func testFallbackSearchHonorsCategoryAndPhotoFilters() async throws {
        let environment = try makeEnvironment()
        let dayA = LocalDayKey(isoDate: "2026-03-04", timeZoneID: "America/Los_Angeles")
        let dayB = LocalDayKey(isoDate: "2026-03-03", timeZoneID: "America/Los_Angeles")
        let dayC = LocalDayKey(isoDate: "2026-03-02", timeZoneID: "America/Los_Angeles")

        try await environment.entryStore.save(makeEntry(dayKey: dayA, rose: "bike ride", includePhoto: false))
        try await environment.entryStore.save(makeEntry(dayKey: dayB, bud: "bike route", includePhoto: true))
        try await environment.entryStore.save(makeEntry(dayKey: dayC, thorn: "quiet day", includePhoto: true))

        let dataSource = JournalDataSource(environment: environment)

        let budMatches = try await dataSource.fallbackSearch(
            text: "bike",
            categories: [.bud],
            hasPhoto: nil
        )
        XCTAssertEqual(budMatches, [dayB])

        let photoMatches = try await dataSource.fallbackSearch(
            text: "bike",
            categories: Set(EntryType.allCases),
            hasPhoto: true
        )
        XCTAssertEqual(photoMatches, [dayB])
    }

    func testLoadSummariesPreservesInputOrder() async throws {
        let environment = try makeEnvironment()
        let dayA = LocalDayKey(isoDate: "2026-03-04", timeZoneID: "America/Los_Angeles")
        let dayB = LocalDayKey(isoDate: "2026-03-03", timeZoneID: "America/Los_Angeles")

        try await environment.entryStore.save(makeEntry(dayKey: dayA, rose: "A"))
        try await environment.entryStore.save(makeEntry(dayKey: dayB, rose: "B"))

        let dataSource = JournalDataSource(environment: environment)
        let summaries = await dataSource.loadSummaries(for: [dayB, dayA])

        XCTAssertEqual(summaries.map(\.dayKey), [dayB, dayA])
    }
}
