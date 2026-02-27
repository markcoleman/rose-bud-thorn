import Foundation
import Observation
import CoreModels
import CoreDate

@MainActor
@Observable
public final class BrowseViewModel {
    public var days: [LocalDayKey] = []
    public var selectedDate: Date = .now
    public var errorMessage: String?

    public let environment: AppEnvironment
    private let dayCalculator: DayKeyCalculator

    public init(environment: AppEnvironment) {
        self.environment = environment
        self.dayCalculator = environment.dayCalculator
    }

    public func loadDays() async {
        do {
            days = try await environment.entryStore.list(range: nil)
            if let first = days.first,
               let date = dayCalculator.date(for: first) {
                selectedDate = date
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func dayKey(for date: Date) -> LocalDayKey {
        dayCalculator.dayKey(for: date)
    }

    public func hasEntry(for dayKey: LocalDayKey) -> Bool {
        days.contains(dayKey)
    }
}
