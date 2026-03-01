import Foundation

public final class FeatureFlagStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        defaults: UserDefaults = .standard,
        key: String = "AppFeatureFlags.v1"
    ) {
        self.defaults = defaults
        self.key = key
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func load(defaults fallback: AppFeatureFlags = AppFeatureFlags()) -> AppFeatureFlags {
        guard let data = defaults.data(forKey: key) else {
            return fallback
        }

        return (try? decoder.decode(AppFeatureFlags.self, from: data)) ?? fallback
    }

    public func save(_ flags: AppFeatureFlags) {
        guard let data = try? encoder.encode(flags) else {
            return
        }
        defaults.set(data, forKey: key)
    }
}
