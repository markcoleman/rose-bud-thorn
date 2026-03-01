import Foundation
import CoreModels
import CoreDate

enum PresentationFormatting {
    private static let dayCalculator = DayKeyCalculator()
    private static let periodCalculator = PeriodKeyCalculator()

    static func localizedDayTitle(for dayKey: LocalDayKey, locale: Locale = .current) -> String {
        guard let date = dayCalculator.date(for: dayKey) else {
            return dayKey.isoDate
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar(for: dayKey)
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    static func summaryTitle(for artifact: SummaryArtifact) -> String {
        "\(artifact.period.title) Summary"
    }

    static func summaryRangeText(for artifact: SummaryArtifact, timeZone: TimeZone = .current, locale: Locale = .current) -> String {
        guard let interval = periodCalculator.range(for: artifact.period, key: artifact.key, timeZone: timeZone) else {
            return artifact.key
        }

        let formatter = DateIntervalFormatter()
        formatter.calendar = calendar(for: timeZone)
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let inclusiveEnd = interval.end.addingTimeInterval(-1)
        return formatter.string(from: interval.start, to: inclusiveEnd)
    }

    static func summaryMetadataText(for artifact: SummaryArtifact, locale: Locale = .current) -> String {
        let generatedText = artifact.generatedAt.formatted(date: .abbreviated, time: .shortened)
        return "Key: \(artifact.key) • Generated \(generatedText)"
    }

    private static func calendar(for dayKey: LocalDayKey) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        return calendar
    }

    private static func calendar(for timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
