import Foundation

public struct ReminderPreferences: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var startHour: Int
    public var endHour: Int
    public var includeWeekends: Bool
    public var allowsEndOfDayFallback: Bool

    public init(
        isEnabled: Bool = false,
        startHour: Int = 18,
        endHour: Int = 20,
        includeWeekends: Bool = true,
        allowsEndOfDayFallback: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.startHour = min(max(startHour, 0), 23)
        self.endHour = min(max(endHour, 0), 23)
        self.includeWeekends = includeWeekends
        self.allowsEndOfDayFallback = allowsEndOfDayFallback
    }
}

public final class ReminderPreferencesStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "ReminderPreferences.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> ReminderPreferences {
        guard let data = defaults.data(forKey: key) else {
            return ReminderPreferences()
        }

        return (try? JSONDecoder().decode(ReminderPreferences.self, from: data)) ?? ReminderPreferences()
    }

    public func save(_ preferences: ReminderPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}
