import Foundation

public final class PromptPreferencesStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "PromptPreferences.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> PromptPreferences {
        guard let data = defaults.data(forKey: key) else {
            return PromptPreferences()
        }

        return (try? JSONDecoder().decode(PromptPreferences.self, from: data)) ?? PromptPreferences()
    }

    public func save(_ preferences: PromptPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}
