import XCTest
@testable import CoreModels

final class CoreModelsTests: XCTestCase {
    func testEntryDayCodableRoundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_708_800_000)
        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")

        var rose = EntryItem(type: .rose, shortText: "Great coffee", journalTextMarkdown: "Met a friend.", updatedAt: now)
        rose.photos = [PhotoRef(id: UUID(), relativePath: "rose/attachments/a.jpg", createdAt: now, pixelWidth: 100, pixelHeight: 200)]
        rose.videos = [VideoRef(id: UUID(), relativePath: "rose/attachments/b.mov", createdAt: now, durationSeconds: 3, pixelWidth: 1920, pixelHeight: 1080, hasAudio: true)]

        let entry = EntryDay(
            dayKey: dayKey,
            roseItem: rose,
            budItem: EntryItem(type: .bud, shortText: "New project", journalTextMarkdown: "", updatedAt: now),
            thornItem: EntryItem(type: .thorn, shortText: "Busy commute", journalTextMarkdown: "", updatedAt: now),
            tags: ["work", "friends"],
            mood: 4,
            createdAt: now,
            updatedAt: now
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(EntryDay.self, from: data)

        XCTAssertEqual(decoded, entry)
        XCTAssertEqual(decoded.dayKey.isoDate, "2026-02-27")
        XCTAssertEqual(decoded.roseItem.photos.count, 1)
        XCTAssertEqual(decoded.roseItem.videos.count, 1)
    }

    func testLegacyV1EntryDecodesWithoutVideosAndReencodesWithoutFavoriteField() throws {
        let legacyJSON = """
        {
          "schemaVersion": 1,
          "dayKey": {
            "isoDate": "2026-02-27",
            "timeZoneID": "America/Los_Angeles"
          },
          "roseItem": {
            "type": "rose",
            "shortText": "Legacy rose",
            "journalTextMarkdown": "",
            "photos": [],
            "metadata": {},
            "updatedAt": "2026-02-27T20:00:00Z"
          },
          "budItem": {
            "type": "bud",
            "shortText": "",
            "journalTextMarkdown": "",
            "photos": [],
            "metadata": {},
            "updatedAt": "2026-02-27T20:00:00Z"
          },
          "thornItem": {
            "type": "thorn",
            "shortText": "",
            "journalTextMarkdown": "",
            "photos": [],
            "metadata": {},
            "updatedAt": "2026-02-27T20:00:00Z"
          },
          "tags": [],
          "mood": null,
          "favorite": false,
          "createdAt": "2026-02-27T20:00:00Z",
          "updatedAt": "2026-02-27T20:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(EntryDay.self, from: Data(legacyJSON.utf8))

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.roseItem.videos, [])
        XCTAssertEqual(decoded.budItem.videos, [])
        XCTAssertEqual(decoded.thornItem.videos, [])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let reencoded = try encoder.encode(decoded)
        let json = String(decoding: reencoded, as: UTF8.self)
        XCTAssertFalse(json.contains("\"favorite\""))
    }

    func testEmptyEntryFactoryCreatesThreeTypes() {
        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")
        let entry = EntryDay.empty(dayKey: dayKey)

        XCTAssertEqual(entry.roseItem.type, .rose)
        XCTAssertEqual(entry.budItem.type, .bud)
        XCTAssertEqual(entry.thornItem.type, .thorn)
        XCTAssertFalse(entry.hasAnyPhotos)
    }

    func testEntryDayCompletionRequiresAllThreeTypes() {
        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")
        var entry = EntryDay.empty(dayKey: dayKey)

        XCTAssertEqual(entry.completionCount, 0)
        XCTAssertFalse(entry.isCompleteForDailyCapture)

        entry.roseItem.shortText = "Rose"
        XCTAssertEqual(entry.completionCount, 1)
        XCTAssertFalse(entry.isCompleteForDailyCapture)

        entry.budItem.journalTextMarkdown = "Bud journal"
        XCTAssertEqual(entry.completionCount, 2)
        XCTAssertFalse(entry.isCompleteForDailyCapture)

        entry.thornItem.videos = [VideoRef(
            id: UUID(),
            relativePath: "thorn/attachments/c.mov",
            createdAt: .now,
            durationSeconds: 3,
            pixelWidth: 1920,
            pixelHeight: 1080,
            hasAudio: true
        )]
        XCTAssertEqual(entry.completionCount, 3)
        XCTAssertTrue(entry.isCompleteForDailyCapture)
    }

    func testEntryDayCompletionCountSupportsMixedContentTypes() {
        let now = Date(timeIntervalSince1970: 1_708_800_000)
        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")
        var entry = EntryDay.empty(dayKey: dayKey)

        entry.roseItem.shortText = "Text"
        entry.budItem.journalTextMarkdown = "Journal"
        entry.thornItem.photos = [PhotoRef(
            id: UUID(),
            relativePath: "thorn/attachments/a.jpg",
            createdAt: now,
            pixelWidth: 100,
            pixelHeight: 200
        )]

        XCTAssertTrue(entry.isRoseComplete)
        XCTAssertTrue(entry.isBudComplete)
        XCTAssertTrue(entry.isThornComplete)
        XCTAssertEqual(entry.completionCount, 3)
        XCTAssertTrue(entry.isCompleteForDailyCapture)
    }

    func testWidgetTodaySnapshotForEmptyEntry() {
        let dayKey = LocalDayKey(isoDate: "2026-03-19", timeZoneID: "America/New_York")
        let entry = EntryDay.empty(dayKey: dayKey)

        let snapshot = entry.widgetTodaySnapshot(now: Date(timeIntervalSince1970: 1_774_380_400))

        XCTAssertEqual(snapshot.dayKeyISODate, "2026-03-19")
        XCTAssertEqual(snapshot.completionCount, 0)
        XCTAssertEqual(snapshot.roseExcerpt, "")
        XCTAssertEqual(snapshot.budExcerpt, "")
        XCTAssertEqual(snapshot.thornExcerpt, "")
        XCTAssertFalse(snapshot.hasAnyContent)
    }

    func testWidgetTodaySnapshotForInProgressEntry() {
        let dayKey = LocalDayKey(isoDate: "2026-03-19", timeZoneID: "America/New_York")
        var entry = EntryDay.empty(dayKey: dayKey)
        entry.roseItem.shortText = "Great workout this morning"
        entry.budItem.photos = [PhotoRef(
            id: UUID(),
            relativePath: "bud/attachments/bud.jpg",
            createdAt: .now,
            pixelWidth: 100,
            pixelHeight: 200
        )]
        entry.updatedAt = Date(timeIntervalSince1970: 1_774_380_400)

        let snapshot = entry.widgetTodaySnapshot(now: Date(timeIntervalSince1970: 1_774_380_401))

        XCTAssertEqual(snapshot.completionCount, 2)
        XCTAssertEqual(snapshot.roseExcerpt, "Great workout this morning")
        XCTAssertEqual(snapshot.budExcerpt, "Media added")
        XCTAssertEqual(snapshot.thornExcerpt, "")
        XCTAssertEqual(snapshot.photos.count, 1)
        XCTAssertEqual(snapshot.photos.first?.type, .bud)
        XCTAssertTrue(snapshot.hasAnyContent)
    }

    func testWidgetTodaySnapshotTruncatesLongExcerpt() {
        let dayKey = LocalDayKey(isoDate: "2026-03-19", timeZoneID: "America/New_York")
        var entry = EntryDay.empty(dayKey: dayKey)
        entry.roseItem.shortText = "This is a very long rose reflection that should be truncated for the widget card display."
        entry.budItem.shortText = "bud"
        entry.thornItem.shortText = "thorn"

        let snapshot = entry.widgetTodaySnapshot(now: .now, excerptLimit: 24)

        XCTAssertEqual(snapshot.completionCount, 3)
        XCTAssertEqual(snapshot.roseExcerpt, "This is a very long ros…")
    }

    func testWidgetTodayDisplayContentRedactsWhenPrivacyLockEnabled() {
        let snapshot = WidgetTodaySnapshot(
            dayKeyISODate: "2026-03-19",
            roseExcerpt: "Morning walk",
            budExcerpt: "Shipping today",
            thornExcerpt: "Tough commute",
            completionCount: 3,
            updatedAt: .now
        )

        let content = WidgetTodayDisplayContent(snapshot: snapshot, isPrivacyLockEnabled: true)

        XCTAssertEqual(content.state, .privacyLocked)
        XCTAssertEqual(content.completionCount, 0)
        XCTAssertEqual(content.roseExcerpt, "")
        XCTAssertEqual(content.budExcerpt, "")
        XCTAssertEqual(content.thornExcerpt, "")
        XCTAssertFalse(content.hasAnyContent)
    }
}
