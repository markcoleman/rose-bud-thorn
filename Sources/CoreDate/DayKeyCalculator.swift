import Foundation
import CoreModels

public struct DayKeyCalculator: Sendable {
    public init() {}

    public func dayKey(for date: Date, timeZone: TimeZone = .current) -> LocalDayKey {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            return LocalDayKey(isoDate: "1970-01-01", timeZoneID: timeZone.identifier)
        }

        let isoDate = String(format: "%04d-%02d-%02d", year, month, day)
        return LocalDayKey(isoDate: isoDate, timeZoneID: timeZone.identifier)
    }

    public func date(for dayKey: LocalDayKey) -> Date? {
        guard
            dayKey.isoDate.count == 10,
            dayKey.isoDate[dayKey.isoDate.index(dayKey.isoDate.startIndex, offsetBy: 4)] == "-",
            dayKey.isoDate[dayKey.isoDate.index(dayKey.isoDate.startIndex, offsetBy: 7)] == "-"
        else {
            return nil
        }

        let segments = dayKey.isoDate.split(separator: "-")
        guard segments.count == 3,
              let year = Int(segments[0]),
              let month = Int(segments[1]),
              let day = Int(segments[2]) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current

        let components = DateComponents(timeZone: calendar.timeZone, year: year, month: month, day: day)
        return calendar.date(from: components)
    }

    public func components(for dayKey: LocalDayKey) -> DateComponents? {
        guard let date = date(for: dayKey) else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
