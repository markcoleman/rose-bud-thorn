import XCTest
@testable import SearchIndex
@testable import DocumentStore
@testable import CoreModels

final class SearchIndexTests: XCTestCase {
    private func makeTempRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func entry(day: String, rose: String, withPhoto: Bool) -> EntryDay {
        let dayKey = LocalDayKey(isoDate: day, timeZoneID: "America/Los_Angeles")
        let photo = withPhoto ? [PhotoRef(id: UUID(), relativePath: "rose/attachments/a.jpg", createdAt: .now)] : []
        return EntryDay(
            dayKey: dayKey,
            roseItem: EntryItem(type: .rose, shortText: rose, journalTextMarkdown: "journal", photos: photo, updatedAt: .now),
            budItem: EntryItem(type: .bud, shortText: "bud", journalTextMarkdown: "", updatedAt: .now),
            thornItem: EntryItem(type: .thorn, shortText: "thorn", journalTextMarkdown: "", updatedAt: .now),
            createdAt: .now,
            updatedAt: .now
        )
    }

    func testSearchByTextAndPhotoFilter() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let repo = try EntryRepositoryImpl(configuration: configuration)
        let index = try FileSearchIndex(configuration: configuration, entryRepository: repo)

        let e1 = entry(day: "2026-02-27", rose: "great hiking day", withPhoto: true)
        let e2 = entry(day: "2026-02-26", rose: "quiet reading", withPhoto: false)

        try await repo.save(e1)
        try await repo.save(e2)
        try await index.upsert(e1)
        try await index.upsert(e2)

        let textResults = try await index.search(EntrySearchQuery(text: "hiking", categories: [.rose], hasPhoto: nil, dateRange: nil))
        XCTAssertEqual(textResults, [e1.dayKey])

        let photoResults = try await index.search(EntrySearchQuery(text: "", categories: [.rose], hasPhoto: true, dateRange: nil))
        XCTAssertEqual(photoResults, [e1.dayKey])
    }

    func testRebuildFromEntries() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let repo = try EntryRepositoryImpl(configuration: configuration)
        let index = try FileSearchIndex(configuration: configuration, entryRepository: repo)

        let e1 = entry(day: "2026-01-01", rose: "new year", withPhoto: false)
        try await repo.save(e1)

        try await index.rebuildFromEntries()
        let results = try await index.search(EntrySearchQuery(text: "new year", categories: [.rose], hasPhoto: nil, dateRange: nil))
        XCTAssertEqual(results, [e1.dayKey])
    }
}
