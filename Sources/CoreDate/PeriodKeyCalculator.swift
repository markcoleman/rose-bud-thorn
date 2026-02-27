import Foundation
import CoreModels

public struct PeriodKeyCalculator: Sendable {
    public init() {}

    public func key(for date: Date, period: SummaryPeriod, timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        switch period {
        case .week:
            let week = calendar.component(.weekOfYear, from: date)
            let year = calendar.component(.yearForWeekOfYear, from: date)
            return String(format: "%04d-W%02d", year, week)
        case .month:
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            return String(format: "%04d-%02d", year, month)
        case .year:
            let year = calendar.component(.year, from: date)
            return String(format: "%04d", year)
        }
    }

    public func range(for period: SummaryPeriod, key: String, timeZone: TimeZone = .current) -> DateInterval? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        switch period {
        case .week:
            return weekRange(for: key, calendar: calendar)
        case .month:
            return monthRange(for: key, calendar: calendar)
        case .year:
            return yearRange(for: key, calendar: calendar)
        }
    }

    private func weekRange(for key: String, calendar: Calendar) -> DateInterval? {
        let parts = key.split(separator: "-W")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let week = Int(parts[1]) else {
            return nil
        }

        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = calendar.timeZone
        comps.yearForWeekOfYear = year
        comps.weekOfYear = week
        comps.weekday = calendar.firstWeekday

        guard let start = calendar.date(from: comps) else {
            return nil
        }
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    private func monthRange(for key: String, calendar: Calendar) -> DateInterval? {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else {
            return nil
        }

        let comps = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: 1)
        guard let start = calendar.date(from: comps) else {
            return nil
        }
        guard let end = calendar.date(byAdding: .month, value: 1, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }

    private func yearRange(for key: String, calendar: Calendar) -> DateInterval? {
        guard let year = Int(key) else {
            return nil
        }

        let comps = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: 1, day: 1)
        guard let start = calendar.date(from: comps) else {
            return nil
        }
        guard let end = calendar.date(byAdding: .year, value: 1, to: start) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }
}
