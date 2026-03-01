import Foundation
import CoreModels
import CoreDate

public actor InsightEngine {
    private let entryStore: EntryStore
    private let completionTracker: EntryCompletionTracker
    private let dayCalculator: DayKeyCalculator
    private let periodCalculator: PeriodKeyCalculator

    public init(
        entryStore: EntryStore,
        completionTracker: EntryCompletionTracker,
        dayCalculator: DayKeyCalculator = DayKeyCalculator(),
        periodCalculator: PeriodKeyCalculator = PeriodKeyCalculator()
    ) {
        self.entryStore = entryStore
        self.completionTracker = completionTracker
        self.dayCalculator = dayCalculator
        self.periodCalculator = periodCalculator
    }

    public func cards(for referenceDate: Date = .now, timeZone: TimeZone = .current) async throws -> [InsightCard] {
        let weekKey = periodCalculator.key(for: referenceDate, period: .week, timeZone: timeZone)
        let monthKey = periodCalculator.key(for: referenceDate, period: .month, timeZone: timeZone)
        var cards: [InsightCard] = []

        let completion = try await completionTracker.summary(for: referenceDate, timeZone: timeZone)
        let completionCount = completion.last7DaysCompleted.filter(\.self).count
        cards.append(
            InsightCard(
                id: "consistency|\(weekKey)",
                type: .consistency,
                period: .week,
                key: weekKey,
                title: "Consistency this week",
                body: "\(completionCount) of 7 days completed with reflection.",
                explainability: "Computed from local completion status for the current 7-day window."
            )
        )

        if let dominantType = try await dominantCategoryCard(weekKey: weekKey, timeZone: timeZone) {
            cards.append(dominantType)
        }

        if let tagCard = try await tagMomentumCard(monthKey: monthKey, timeZone: timeZone) {
            cards.append(tagCard)
        }

        if let moodCard = try await moodTrendCard(weekKey: weekKey, referenceDate: referenceDate, timeZone: timeZone) {
            cards.append(moodCard)
        }

        return cards
    }

    private func dominantCategoryCard(weekKey: String, timeZone: TimeZone) async throws -> InsightCard? {
        guard let range = periodCalculator.range(for: .week, key: weekKey, timeZone: timeZone) else {
            return nil
        }

        let counts = try await categoryCounts(in: range)
        guard let best = EntryType.allCases.max(by: { lhs, rhs in
            let leftCount = counts[lhs, default: 0]
            let rightCount = counts[rhs, default: 0]
            if leftCount == rightCount {
                return lhs.rawValue > rhs.rawValue
            }
            return leftCount < rightCount
        }),
            counts[best, default: 0] > 0 else {
            return nil
        }

        return InsightCard(
            id: "dominant|\(weekKey)",
            type: .dominantCategory,
            period: .week,
            key: weekKey,
            title: "Most active category",
            body: "\(best.title) led with \(counts[best, default: 0]) captured moments.",
            explainability: "Counts include entries with text or media from local week \(weekKey)."
        )
    }

    private func tagMomentumCard(monthKey: String, timeZone: TimeZone) async throws -> InsightCard? {
        guard let range = periodCalculator.range(for: .month, key: monthKey, timeZone: timeZone) else {
            return nil
        }

        let entries = try await entries(in: range)
        var tagCounts: [String: Int] = [:]
        for entry in entries {
            for tag in entry.tags.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }).filter({ !$0.isEmpty }) {
                tagCounts[tag, default: 0] += 1
            }
        }

        guard let top = tagCounts.max(by: { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key > rhs.key
            }
            return lhs.value < rhs.value
        }) else {
            return nil
        }

        return InsightCard(
            id: "tag|\(monthKey)",
            type: .tagMomentum,
            period: .month,
            key: monthKey,
            title: "Theme momentum",
            body: "\"\(top.key)\" appears in \(top.value) entries this month.",
            explainability: "Calculated from local entry tags for month \(monthKey)."
        )
    }

    private func moodTrendCard(weekKey: String, referenceDate: Date, timeZone: TimeZone) async throws -> InsightCard? {
        guard let currentRange = periodCalculator.range(for: .week, key: weekKey, timeZone: timeZone),
              let previousDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: -7, to: referenceDate) else {
            return nil
        }

        let previousWeekKey = periodCalculator.key(for: previousDate, period: .week, timeZone: timeZone)
        guard let previousRange = periodCalculator.range(for: .week, key: previousWeekKey, timeZone: timeZone) else {
            return nil
        }

        let currentAverage = try await averageMood(in: currentRange)
        let previousAverage = try await averageMood(in: previousRange)
        guard let currentAverage else {
            return nil
        }

        let comparisonText: String
        if let previousAverage {
            let delta = currentAverage - previousAverage
            if abs(delta) < 0.1 {
                comparisonText = "Mood stayed steady week over week."
            } else if delta > 0 {
                comparisonText = String(format: "Average mood is up by %.1f points vs last week.", delta)
            } else {
                comparisonText = String(format: "Average mood is down by %.1f points vs last week.", abs(delta))
            }
        } else {
            comparisonText = String(format: "Average mood this week is %.1f.", currentAverage)
        }

        return InsightCard(
            id: "mood|\(weekKey)",
            type: .moodTrend,
            period: .week,
            key: weekKey,
            title: "Mood trend",
            body: comparisonText,
            explainability: "Uses the optional 1-5 mood score saved in local entries."
        )
    }

    private func entries(in range: DateInterval) async throws -> [EntryDay] {
        let dayKeys = try await entryStore.list(range: range).sorted(by: >)
        var results: [EntryDay] = []
        results.reserveCapacity(dayKeys.count)
        for dayKey in dayKeys {
            results.append(try await entryStore.load(day: dayKey))
        }
        return results
    }

    private func categoryCounts(in range: DateInterval) async throws -> [EntryType: Int] {
        let entries = try await entries(in: range)
        var counts: [EntryType: Int] = [:]

        for entry in entries {
            for type in EntryType.allCases {
                let item = entry.item(for: type)
                if hasContent(item: item) {
                    counts[type, default: 0] += 1
                }
            }
        }

        return counts
    }

    private func averageMood(in range: DateInterval) async throws -> Double? {
        let entries = try await entries(in: range)
        let moods = entries.compactMap(\.mood)
        guard !moods.isEmpty else {
            return nil
        }

        let total = moods.reduce(0, +)
        return Double(total) / Double(moods.count)
    }

    private func hasContent(item: EntryItem) -> Bool {
        if !item.shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        if !item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return item.hasMedia
    }
}
