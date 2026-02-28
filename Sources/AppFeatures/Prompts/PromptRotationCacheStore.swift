import Foundation

struct PromptRotationCache: Codable, Equatable, Sendable {
    var selectedByDayBucket: [String: Int] = [:]
    var usedByWeekBucket: [String: [Int]] = [:]
    var lastPromptByType: [String: String] = [:]
    var lastDayByType: [String: String] = [:]
}

public final class PromptRotationCacheStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "PromptRotationCache.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PromptRotationCache {
        guard let data = defaults.data(forKey: key) else {
            return PromptRotationCache()
        }
        return (try? JSONDecoder().decode(PromptRotationCache.self, from: data)) ?? PromptRotationCache()
    }

    func save(_ cache: PromptRotationCache) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: key)
    }
}
