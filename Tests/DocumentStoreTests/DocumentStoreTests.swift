import XCTest
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics
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

    func testLoadMigratesLegacyV1EntryAndRewritesWithoutFavorite() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let repo = try EntryRepositoryImpl(configuration: configuration)
        let dayKey = LocalDayKey(isoDate: "2026-03-05", timeZoneID: "America/Los_Angeles")
        let now = Date(timeIntervalSince1970: 1_772_201_600)

        let entryURL = FileLayout(rootURL: root).entryFileURL(for: dayKey)
        try FileManager.default.createDirectory(at: entryURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try makeLegacyV1EntryJSON(dayKey: dayKey, updatedAt: now, favorite: true).write(to: entryURL)

        let loaded = try await repo.load(day: dayKey)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.schemaVersion, EntryDay.currentSchemaVersion)
        XCTAssertEqual(loaded?.roseItem.shortText, "Legacy rose")

        let migratedData = try Data(contentsOf: entryURL)
        let migratedObject = try XCTUnwrap(JSONSerialization.jsonObject(with: migratedData) as? [String: Any])
        XCTAssertEqual(migratedObject["schemaVersion"] as? Int, EntryDay.currentSchemaVersion)
        XCTAssertNil(migratedObject["favorite"])
    }

    func testMergeWithLegacyEntryArchivesConflictWithoutFavoriteField() async throws {
        let root = try makeTempRoot()
        let configuration = DocumentStoreConfiguration(rootURL: root)
        let repo = try EntryRepositoryImpl(configuration: configuration)
        let dayKey = LocalDayKey(isoDate: "2026-03-06", timeZoneID: "America/Los_Angeles")

        let oldDate = Date(timeIntervalSince1970: 1_772_115_200)
        let newDate = Date(timeIntervalSince1970: 1_772_201_600)

        let entryURL = FileLayout(rootURL: root).entryFileURL(for: dayKey)
        try FileManager.default.createDirectory(at: entryURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try makeLegacyV1EntryJSON(dayKey: dayKey, updatedAt: oldDate, favorite: true).write(to: entryURL)

        var incoming = makeEntry(day: dayKey.isoDate, updatedAt: newDate)
        incoming.roseItem.shortText = "Updated rose"
        try await repo.save(incoming)

        let loaded = try await repo.load(day: dayKey)
        XCTAssertEqual(loaded?.schemaVersion, EntryDay.currentSchemaVersion)
        XCTAssertEqual(loaded?.roseItem.shortText, "Updated rose")

        let conflictsRoot = FileLayout(rootURL: root).conflictsRoot.appendingPathComponent(dayKey.isoDate)
        let contents = try FileManager.default.contentsOfDirectory(at: conflictsRoot, includingPropertiesForKeys: nil)
        XCTAssertFalse(contents.isEmpty)

        let archiveData = try Data(contentsOf: try XCTUnwrap(contents.first))
        let archiveJSON = String(decoding: archiveData, as: UTF8.self)
        XCTAssertFalse(archiveJSON.contains("\"favorite\""))
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

    func testStoreLocationMigratorCopiesLegacyDataAndSetsMarker() throws {
        let legacy = try makeTempRoot()
        let shared = try makeTempRoot()
        let defaults = UserDefaults(suiteName: "StoreLocationMigrator.\(UUID().uuidString)")!
        let migrationKey = "migration.test.v1"

        let legacyEntry = legacy
            .appendingPathComponent("Entries", isDirectory: true)
            .appendingPathComponent("2026", isDirectory: true)
            .appendingPathComponent("03", isDirectory: true)
            .appendingPathComponent("01", isDirectory: true)
            .appendingPathComponent("entry.json")
        try FileManager.default.createDirectory(at: legacyEntry.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("legacy-entry".utf8).write(to: legacyEntry)

        try StoreLocationMigrator.migrateLegacyStoreIfNeeded(
            from: legacy,
            to: shared,
            defaults: defaults,
            migrationKey: migrationKey
        )

        let sharedEntry = shared
            .appendingPathComponent("Entries", isDirectory: true)
            .appendingPathComponent("2026", isDirectory: true)
            .appendingPathComponent("03", isDirectory: true)
            .appendingPathComponent("01", isDirectory: true)
            .appendingPathComponent("entry.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: sharedEntry.path))
        XCTAssertEqual(try String(contentsOf: sharedEntry, encoding: .utf8), "legacy-entry")
        XCTAssertTrue(defaults.bool(forKey: migrationKey))
    }

    func testStoreLocationMigratorDoesNotOverwriteExistingDestinationFiles() throws {
        let legacy = try makeTempRoot()
        let shared = try makeTempRoot()
        let defaults = UserDefaults(suiteName: "StoreLocationMigrator.\(UUID().uuidString)")!

        let relativePath = "Entries/2026/03/01/entry.json"
        let legacyFile = legacy.appendingPathComponent(relativePath)
        let sharedFile = shared.appendingPathComponent(relativePath)

        try FileManager.default.createDirectory(at: legacyFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: sharedFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("legacy-version".utf8).write(to: legacyFile)
        try Data("shared-version".utf8).write(to: sharedFile)

        try StoreLocationMigrator.migrateLegacyStoreIfNeeded(
            from: legacy,
            to: shared,
            defaults: defaults,
            migrationKey: "migration.overwrite-test.v1"
        )

        XCTAssertEqual(try String(contentsOf: sharedFile, encoding: .utf8), "shared-version")
    }

    func testStoreLocationMigratorIsIdempotentAfterMarkerIsSet() throws {
        let legacy = try makeTempRoot()
        let shared = try makeTempRoot()
        let defaults = UserDefaults(suiteName: "StoreLocationMigrator.\(UUID().uuidString)")!
        let migrationKey = "migration.idempotent.v1"

        let firstLegacyFile = legacy.appendingPathComponent("Entries/2026/03/01/entry.json")
        try FileManager.default.createDirectory(at: firstLegacyFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("first".utf8).write(to: firstLegacyFile)

        try StoreLocationMigrator.migrateLegacyStoreIfNeeded(
            from: legacy,
            to: shared,
            defaults: defaults,
            migrationKey: migrationKey
        )

        let secondLegacyFile = legacy.appendingPathComponent("Entries/2026/03/02/entry.json")
        try FileManager.default.createDirectory(at: secondLegacyFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("second".utf8).write(to: secondLegacyFile)

        try StoreLocationMigrator.migrateLegacyStoreIfNeeded(
            from: legacy,
            to: shared,
            defaults: defaults,
            migrationKey: migrationKey
        )

        let secondSharedFile = shared.appendingPathComponent("Entries/2026/03/02/entry.json")
        XCTAssertFalse(FileManager.default.fileExists(atPath: secondSharedFile.path))
    }

    func testImageCaptureDateValidatorMatchesExpectedDay() throws {
        let imageURL = try makeTempRoot().appendingPathComponent("captured.jpg")
        try writeJPEG(
            to: imageURL,
            exifDateTimeOriginal: "2026:03:01 10:00:00",
            tiffDateTime: nil
        )

        let expected = LocalDayKey(isoDate: "2026-03-01", timeZoneID: "America/New_York")
        let result = ImageCaptureDateValidator.validateImage(at: imageURL, matches: expected)
        XCTAssertEqual(result, .matches)
    }

    func testImageCaptureDateValidatorRejectsDifferentDay() throws {
        let imageURL = try makeTempRoot().appendingPathComponent("captured.jpg")
        try writeJPEG(
            to: imageURL,
            exifDateTimeOriginal: "2026:02:28 22:45:00",
            tiffDateTime: nil
        )

        let expected = LocalDayKey(isoDate: "2026-03-01", timeZoneID: "America/New_York")
        let result = ImageCaptureDateValidator.validateImage(at: imageURL, matches: expected)

        guard case .mismatched(let actual) = result else {
            return XCTFail("Expected mismatched day result.")
        }
        XCTAssertEqual(actual.isoDate, "2026-02-28")
    }

    func testImageCaptureDateValidatorRejectsMissingTimestamp() throws {
        let imageURL = try makeTempRoot().appendingPathComponent("captured.jpg")
        try writeJPEG(
            to: imageURL,
            exifDateTimeOriginal: nil,
            tiffDateTime: nil
        )

        let expected = LocalDayKey(isoDate: "2026-03-01", timeZoneID: "America/New_York")
        let result = ImageCaptureDateValidator.validateImage(at: imageURL, matches: expected)
        XCTAssertEqual(result, .missingTimestamp)
    }

    private func writeJPEG(
        to url: URL,
        exifDateTimeOriginal: String?,
        tiffDateTime: String?
    ) throws {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let image = context.makeImage(),
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else {
            throw NSError(domain: "DocumentStoreTests", code: 1)
        }

        var properties: [CFString: Any] = [:]
        if let exifDateTimeOriginal {
            properties[kCGImagePropertyExifDictionary] = [
                kCGImagePropertyExifDateTimeOriginal: exifDateTimeOriginal
            ]
        }
        if let tiffDateTime {
            properties[kCGImagePropertyTIFFDictionary] = [
                kCGImagePropertyTIFFDateTime: tiffDateTime
            ]
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        if !CGImageDestinationFinalize(destination) {
            throw NSError(domain: "DocumentStoreTests", code: 2)
        }
    }

    private func makeLegacyV1EntryJSON(
        dayKey: LocalDayKey,
        updatedAt: Date,
        favorite: Bool
    ) throws -> Data {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let isoTimestamp = formatter.string(from: updatedAt)

        let json: [String: Any] = [
            "schemaVersion": 1,
            "dayKey": [
                "isoDate": dayKey.isoDate,
                "timeZoneID": dayKey.timeZoneID,
            ],
            "roseItem": [
                "type": "rose",
                "shortText": "Legacy rose",
                "journalTextMarkdown": "",
                "photos": [],
                "videos": [],
                "metadata": [:],
                "updatedAt": isoTimestamp,
            ],
            "budItem": [
                "type": "bud",
                "shortText": "",
                "journalTextMarkdown": "",
                "photos": [],
                "videos": [],
                "metadata": [:],
                "updatedAt": isoTimestamp,
            ],
            "thornItem": [
                "type": "thorn",
                "shortText": "",
                "journalTextMarkdown": "",
                "photos": [],
                "videos": [],
                "metadata": [:],
                "updatedAt": isoTimestamp,
            ],
            "tags": [],
            "mood": NSNull(),
            "favorite": favorite,
            "createdAt": isoTimestamp,
            "updatedAt": isoTimestamp,
        ]

        return try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
    }
}
