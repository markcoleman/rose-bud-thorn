import XCTest
@testable import Summaries
@testable import DocumentStore
@testable import CoreModels
@testable import CoreDate

final class SummariesTests: XCTestCase {
    private func makeTempRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func makeEntry(day: String, rose: String, bud: String, thorn: String) -> EntryDay {
        EntryDay(
            dayKey: LocalDayKey(isoDate: day, timeZoneID: "America/Los_Angeles"),
            roseItem: EntryItem(type: .rose, shortText: rose, journalTextMarkdown: "Loved this day.", updatedAt: .now),
            budItem: EntryItem(type: .bud, shortText: bud, journalTextMarkdown: "Excited for tomorrow.", updatedAt: .now),
            thornItem: EntryItem(type: .thorn, shortText: thorn, journalTextMarkdown: "This was hard.", updatedAt: .now),
            createdAt: .now,
            updatedAt: .now
        )
    }

    func testGenerateWeeklySummaryPersistsArtifacts() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let repo = try EntryRepositoryImpl(configuration: configuration)
        let service = try SummaryServiceImpl(configuration: configuration, entryRepository: repo)

        try await repo.save(makeEntry(day: "2026-02-23", rose: "Team lunch", bud: "Launch prep", thorn: "Bug triage"))
        try await repo.save(makeEntry(day: "2026-02-24", rose: "Long walk", bud: "New feature", thorn: "Late meeting"))

        let key = "2026-W09"
        let artifact = try await service.generate(period: .week, key: key)

        XCTAssertEqual(artifact.key, key)
        XCTAssertTrue(artifact.contentMarkdown.contains("## Highlights"))
        XCTAssertTrue(artifact.contentMarkdown.contains("## Rose Patterns"))

        let markdownURL = FileLayout(rootURL: root).summaryMarkdownURL(period: .week, key: key)
        XCTAssertTrue(FileManager.default.fileExists(atPath: markdownURL.path))

        let loaded = try await service.load(period: .week, key: key)
        XCTAssertEqual(loaded?.key, artifact.key)

        let listed = try await service.list(period: .week)
        XCTAssertEqual(listed.count, 1)
    }

    func testHighlightExtractorProducesTokens() {
        let extractor = HighlightExtractor()
        let entry = makeEntry(day: "2026-02-27", rose: "hiking sunset", bud: "hiking again", thorn: "traffic")

        let highlights = extractor.extract(from: [entry], limit: 3)
        XCTAssertFalse(highlights.isEmpty)
    }
}
