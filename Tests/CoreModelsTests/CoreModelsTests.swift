import XCTest
@testable import CoreModels

final class CoreModelsTests: XCTestCase {
    func testEntryDayCodableRoundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_708_800_000)
        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")

        var rose = EntryItem(type: .rose, shortText: "Great coffee", journalTextMarkdown: "Met a friend.", updatedAt: now)
        rose.photos = [PhotoRef(id: UUID(), relativePath: "rose/attachments/a.jpg", createdAt: now, pixelWidth: 100, pixelHeight: 200)]

        let entry = EntryDay(
            dayKey: dayKey,
            roseItem: rose,
            budItem: EntryItem(type: .bud, shortText: "New project", journalTextMarkdown: "", updatedAt: now),
            thornItem: EntryItem(type: .thorn, shortText: "Busy commute", journalTextMarkdown: "", updatedAt: now),
            tags: ["work", "friends"],
            mood: 4,
            favorite: true,
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
    }

    func testEmptyEntryFactoryCreatesThreeTypes() {
        let dayKey = LocalDayKey(isoDate: "2026-02-27", timeZoneID: "America/Los_Angeles")
        let entry = EntryDay.empty(dayKey: dayKey)

        XCTAssertEqual(entry.roseItem.type, .rose)
        XCTAssertEqual(entry.budItem.type, .bud)
        XCTAssertEqual(entry.thornItem.type, .thorn)
        XCTAssertFalse(entry.hasAnyPhotos)
    }
}
