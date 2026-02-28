import Foundation
import CoreDate
import CoreModels

public struct EntryCompletionSummary: Equatable, Sendable {
    public var isTodayComplete: Bool
    public var streakCount: Int
    public var previousStreakCount: Int
    public var last7DaysCompleted: [Bool]

    public init(
        isTodayComplete: Bool = false,
        streakCount: Int = 0,
        previousStreakCount: Int = 0,
        last7DaysCompleted: [Bool] = Array(repeating: false, count: 7)
    ) {
        self.isTodayComplete = isTodayComplete
        self.streakCount = streakCount
        self.previousStreakCount = previousStreakCount
        self.last7DaysCompleted = last7DaysCompleted
    }
}

public actor EntryCompletionTracker {
    private let entryStore: EntryStore
    private let dayCalculator: DayKeyCalculator

    public init(entryStore: EntryStore, dayCalculator: DayKeyCalculator) {
        self.entryStore = entryStore
        self.dayCalculator = dayCalculator
    }

    public func summary(for now: Date = .now, timeZone: TimeZone = .current) async throws -> EntryCompletionSummary {
        let today = dayCalculator.dayKey(for: now, timeZone: timeZone)
        let allDays = try await entryStore.list(range: nil)
        var completed: Set<String> = []
        for day in allDays {
            let entry = try await entryStore.load(day: day)
            if entry.isCompleteForDailyCapture {
                completed.insert(day.isoDate)
            }
        }

        let isTodayComplete = completed.contains(today.isoDate)
        let streakCount = consecutiveCompletions(endingAt: now, completed: completed, timeZone: timeZone)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let previousStreakCount = consecutiveCompletions(endingAt: yesterday, completed: completed, timeZone: timeZone)

        let last7 = sevenDayCompletion(endingAt: now, completed: completed, timeZone: timeZone)

        return EntryCompletionSummary(
            isTodayComplete: isTodayComplete,
            streakCount: streakCount,
            previousStreakCount: previousStreakCount,
            last7DaysCompleted: last7
        )
    }

    private func consecutiveCompletions(endingAt date: Date, completed: Set<String>, timeZone: TimeZone) -> Int {
        var count = 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        for offset in 0..<365 {
            guard let candidateDate = calendar.date(byAdding: .day, value: -offset, to: date) else {
                break
            }
            let day = dayCalculator.dayKey(for: candidateDate, timeZone: timeZone)
            guard completed.contains(day.isoDate) else {
                break
            }
            count += 1
        }

        return count
    }

    private func sevenDayCompletion(endingAt date: Date, completed: Set<String>, timeZone: TimeZone) -> [Bool] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        return (0..<7).reversed().map { offset in
            let candidateDate = calendar.date(byAdding: .day, value: -offset, to: date) ?? date
            let day = dayCalculator.dayKey(for: candidateDate, timeZone: timeZone)
            return completed.contains(day.isoDate)
        }
    }
}
