import XCTest
@testable import DocumentStore
@testable import CoreModels
@testable import CoreDate

final class DocumentStoreTests: XCTestCase {
    private func makeTempRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func makeEntry(day: String, updatedAt: Date) -> EntryDay {
        let dayKey = LocalDayKey(isoDate: day, timeZoneID: "America/Los_Angeles")
        return EntryDay(
            dayKey: dayKey,
            roseItem: EntryItem(type: .rose, shortText: "Rose \(day)", journalTextMarkdown: "", updatedAt: updatedAt),
            budItem: EntryItem(type: .bud, shortText: "Bud \(day)", journalTextMarkdown: "", updatedAt: updatedAt),
            thornItem: EntryItem(type: .thorn, shortText: "Thorn \(day)", journalTextMarkdown: "", updatedAt: updatedAt),
            createdAt: updatedAt,
            updatedAt: updatedAt
        )
    }

    func testCRUDAndList() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let repo = try EntryRepositoryImpl(configuration: configuration)

        let entry = makeEntry(day: "2026-02-27", updatedAt: .now)
        try await repo.save(entry)

        let loaded = try await repo.load(day: entry.dayKey)
        XCTAssertEqual(loaded?.roseItem.shortText, "Rose 2026-02-27")

        let listed = try await repo.list(range: nil)
        XCTAssertEqual(listed.count, 1)

        try await repo.delete(day: entry.dayKey)
        let deleted = try await repo.load(day: entry.dayKey)
        XCTAssertNil(deleted)
    }

    func testMergeByLatestUpdatedAtAndConflictArchive() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let repo = try EntryRepositoryImpl(configuration: configuration)

        let oldDate = Date(timeIntervalSince1970: 10)
        let newDate = Date(timeIntervalSince1970: 20)

        let first = makeEntry(day: "2026-02-27", updatedAt: oldDate)
        try await repo.save(first)

        var second = makeEntry(day: "2026-02-27", updatedAt: newDate)
        second.roseItem.shortText = "New Rose"
        second.budItem.shortText = "New Bud"
        second.thornItem.shortText = "New Thorn"

        try await repo.save(second)

        let loaded = try await repo.load(day: second.dayKey)
        XCTAssertEqual(loaded?.roseItem.shortText, "New Rose")

        let conflictsRoot = FileLayout(rootURL: root).conflictsRoot.appendingPathComponent(second.dayKey.isoDate)
        let contents = try FileManager.default.contentsOfDirectory(at: conflictsRoot, includingPropertiesForKeys: nil)
        XCTAssertFalse(contents.isEmpty)
    }

    func testAttachmentImportAndRemove() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let attachments = try AttachmentRepositoryImpl(configuration: configuration)

        let source = root.appendingPathComponent("fixture.jpg")
        try Data("image-bytes".utf8).write(to: source)

        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")
        let ref = try await attachments.importImage(from: source, day: dayKey, type: .rose)

        let storedURL = FileLayout(rootURL: root).dayDirectory(for: dayKey).appendingPathComponent(ref.relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storedURL.path))

        try await attachments.remove(ref, day: dayKey)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storedURL.path))
    }

    func testVideoAttachmentImportAndRemove() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let attachments = try AttachmentRepositoryImpl(configuration: configuration)

        let source = root.appendingPathComponent("fixture.mov")
        try Data("video-bytes".utf8).write(to: source)

        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")
        let ref = try await attachments.importVideo(from: source, day: dayKey, type: .bud)

        let storedURL = FileLayout(rootURL: root).dayDirectory(for: dayKey).appendingPathComponent(ref.relativePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storedURL.path))
        XCTAssertGreaterThanOrEqual(ref.durationSeconds, 0)

        try await attachments.removeVideo(ref, day: dayKey)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storedURL.path))
    }
}
