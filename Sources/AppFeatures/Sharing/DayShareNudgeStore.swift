import Foundation
import CoreModels

public final class DayShareNudgeStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "DayShareNudgeDismissedTokens.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func shouldPresentPrompt(for dayKey: LocalDayKey) -> Bool {
        !dismissedTokens.contains(Self.dayToken(for: dayKey))
    }

    public func markHandled(for dayKey: LocalDayKey) {
        var tokens = dismissedTokens
        tokens.insert(Self.dayToken(for: dayKey))
        defaults.set(Array(tokens).sorted(), forKey: key)
    }

    public func reset() {
        defaults.removeObject(forKey: key)
    }

    public static func dayToken(for dayKey: LocalDayKey) -> String {
        "\(dayKey.isoDate)|\(dayKey.timeZoneID)"
    }

    private var dismissedTokens: Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }
}
