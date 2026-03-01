import XCTest
@testable import CoreDate
@testable import CoreModels

final class CoreDateTests: XCTestCase {
    private let dayCalculator = DayKeyCalculator()
    private let periodCalculator = PeriodKeyCalculator()

    func testLocalDayKeyRespectsTimeZone() {
        let utc = TimeZone(secondsFromGMT: 0)!
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: "2024-03-06T00:00:00Z")!

        let utcKey = dayCalculator.dayKey(for: date, timeZone: utc)
        let pstKey = dayCalculator.dayKey(for: date, timeZone: pst)

        XCTAssertEqual(utcKey.isoDate, "2024-03-06")
        XCTAssertEqual(pstKey.isoDate, "2024-03-05")
    }

    func testDayKeyRoundTripAroundDST() {
        let dayKey = LocalDayKey(isoDate: "2026-03-08", timeZoneID: "America/Los_Angeles")
        let date = dayCalculator.date(for: dayKey)

        XCTAssertNotNil(date)
        let roundTrip = dayCalculator.dayKey(for: date!, timeZone: TimeZone(identifier: dayKey.timeZoneID)!)
        XCTAssertEqual(roundTrip.isoDate, dayKey.isoDate)
    }

    func testWeekKeyAndRange() {
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 2
        comps.day = 23
        comps.timeZone = tz

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: comps)!

        let key = periodCalculator.key(for: date, period: .week, timeZone: tz)
        XCTAssertEqual(key, "2026-W09")

        let range = periodCalculator.range(for: .week, key: key, timeZone: tz)
        XCTAssertNotNil(range)
        XCTAssertEqual(Int(range!.duration), 7 * 24 * 3600)
    }

    func testLeapYearMonthRange() {
        let tz = TimeZone(identifier: "America/New_York")!
        let range = periodCalculator.range(for: .month, key: "2024-02", timeZone: tz)

        XCTAssertNotNil(range)
        let days = Int(range!.duration / (24 * 3600))
        XCTAssertEqual(days, 29)
    }

    func testInvalidPeriodKeysReturnNilRange() {
        let tz = TimeZone(identifier: "America/New_York")!

        XCTAssertNil(periodCalculator.range(for: .week, key: "bad-week", timeZone: tz))
        XCTAssertNil(periodCalculator.range(for: .month, key: "2026-AA", timeZone: tz))
        XCTAssertNil(periodCalculator.range(for: .year, key: "year-2026", timeZone: tz))
    }
}
