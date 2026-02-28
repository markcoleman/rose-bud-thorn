import Foundation
import CoreModels
import CoreDate

public final class PromptSelector: @unchecked Sendable {
    private let preferencesStore: PromptPreferencesStore
    private let cacheStore: PromptRotationCacheStore
    private let dayCalculator: DayKeyCalculator
    private let periodCalculator: PeriodKeyCalculator

    public init(
        preferencesStore: PromptPreferencesStore = PromptPreferencesStore(),
        cacheStore: PromptRotationCacheStore = PromptRotationCacheStore(),
        dayCalculator: DayKeyCalculator = DayKeyCalculator(),
        periodCalculator: PeriodKeyCalculator = PeriodKeyCalculator()
    ) {
        self.preferencesStore = preferencesStore
        self.cacheStore = cacheStore
        self.dayCalculator = dayCalculator
        self.periodCalculator = periodCalculator
    }

    public func loadPreferences() -> PromptPreferences {
        preferencesStore.load()
    }

    public func savePreferences(_ preferences: PromptPreferences) {
        preferencesStore.save(preferences)
    }

    public func prompts(for dayKey: LocalDayKey, preferences: PromptPreferences) -> [EntryType: PromptSelection] {
        var results: [EntryType: PromptSelection] = [:]
        for type in EntryType.allCases {
            if let selection = prompt(for: type, dayKey: dayKey, preferences: preferences) {
                results[type] = selection
            }
        }
        return results
    }

    public func prompt(
        for type: EntryType,
        dayKey: LocalDayKey,
        preferences: PromptPreferences
    ) -> PromptSelection? {
        guard preferences.isEnabled, preferences.isTypeEnabled(type) else {
            return nil
        }

        let theme = resolveTheme(for: dayKey, preference: preferences.themePreference)
        let prompts = PromptPackLibrary.prompts(for: theme, type: type)
        guard !prompts.isEmpty else {
            return nil
        }

        var cache = cacheStore.load()
        let dayBucket = dayBucketKey(for: dayKey, theme: theme, mode: preferences.selectionMode, type: type)

        if let index = cache.selectedByDayBucket[dayBucket], prompts.indices.contains(index) {
            return PromptSelection(type: type, theme: theme, text: prompts[index])
        }

        let index = nextPromptIndex(
            prompts: prompts,
            type: type,
            theme: theme,
            dayKey: dayKey,
            preferences: preferences,
            cache: cache
        )

        cache.selectedByDayBucket[dayBucket] = index
        cache.lastPromptByType[type.rawValue] = prompts[index]
        cache.lastDayByType[type.rawValue] = dayKey.isoDate

        if preferences.selectionMode == .deterministic {
            let weekBucket = weekBucketKey(for: dayKey, theme: theme, type: type)
            var usedIndexes = cache.usedByWeekBucket[weekBucket] ?? []
            if Set(usedIndexes).count >= prompts.count {
                usedIndexes.removeAll()
            }
            usedIndexes.append(index)
            cache.usedByWeekBucket[weekBucket] = usedIndexes
        }

        prune(cache: &cache, dayKey: dayKey)
        cacheStore.save(cache)
        return PromptSelection(type: type, theme: theme, text: prompts[index])
    }

    private func nextPromptIndex(
        prompts: [String],
        type: EntryType,
        theme: PromptTheme,
        dayKey: LocalDayKey,
        preferences: PromptPreferences,
        cache: PromptRotationCache
    ) -> Int {
        if preferences.selectionMode == .random {
            return Int.random(in: 0..<prompts.count)
        }

        let weekBucket = weekBucketKey(for: dayKey, theme: theme, type: type)
        var usedIndexes = Set(cache.usedByWeekBucket[weekBucket] ?? [])
        if usedIndexes.count >= prompts.count {
            usedIndexes.removeAll()
        }

        let previousPrompt = previousDayPrompt(for: type, dayKey: dayKey, cache: cache)
        let start = stableIndex(
            for: "\(dayKey.isoDate)|\(dayKey.timeZoneID)|\(theme.rawValue)|\(type.rawValue)",
            count: prompts.count
        )

        let candidateIndexes = (0..<prompts.count).map { (start + $0) % prompts.count }

        if let candidate = candidateIndexes.first(where: { index in
            !usedIndexes.contains(index) &&
            (previousPrompt == nil || prompts.count == 1 || prompts[index] != previousPrompt)
        }) {
            return candidate
        }

        if let candidate = candidateIndexes.first(where: { !usedIndexes.contains($0) }) {
            return candidate
        }

        if let previousPrompt {
            if let candidate = candidateIndexes.first(where: { prompts[$0] != previousPrompt }) {
                return candidate
            }
        }

        return start
    }

    private func resolveTheme(for dayKey: LocalDayKey, preference: PromptThemePreference) -> PromptTheme {
        if let fixed = preference.resolvedTheme {
            return fixed
        }

        let index = stableIndex(
            for: "\(dayKey.isoDate)|\(dayKey.timeZoneID)|theme",
            count: PromptTheme.allCases.count
        )
        return PromptTheme.allCases[index]
    }

    private func previousDayPrompt(for type: EntryType, dayKey: LocalDayKey, cache: PromptRotationCache) -> String? {
        guard let previousDay = cache.lastDayByType[type.rawValue],
              let previousPrompt = cache.lastPromptByType[type.rawValue] else {
            return nil
        }

        let previousKey = LocalDayKey(isoDate: previousDay, timeZoneID: dayKey.timeZoneID)
        guard let previousDate = dayCalculator.date(for: previousKey),
              let currentDate = dayCalculator.date(for: dayKey) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        let dayDelta = calendar.dateComponents([.day], from: previousDate, to: currentDate).day
        guard dayDelta == 1 else {
            return nil
        }

        return previousPrompt
    }

    private func weekBucketKey(for dayKey: LocalDayKey, theme: PromptTheme, type: EntryType) -> String {
        let weekKey = weekKey(for: dayKey)
        return "\(weekKey)|\(theme.rawValue)|\(type.rawValue)"
    }

    private func weekKey(for dayKey: LocalDayKey) -> String {
        guard let date = dayCalculator.date(for: dayKey) else {
            return "unknown-week"
        }
        let timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        return periodCalculator.key(for: date, period: .week, timeZone: timeZone)
    }

    private func dayBucketKey(
        for dayKey: LocalDayKey,
        theme: PromptTheme,
        mode: PromptSelectionMode,
        type: EntryType
    ) -> String {
        "\(dayKey.isoDate)|\(dayKey.timeZoneID)|\(theme.rawValue)|\(mode.rawValue)|\(type.rawValue)"
    }

    private func stableIndex(for input: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in input.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return Int(hash % UInt64(count))
    }

    private func prune(cache: inout PromptRotationCache, dayKey: LocalDayKey) {
        guard let currentDate = dayCalculator.date(for: dayKey),
              let cutoffDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: -21, to: currentDate) else {
            return
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoffISO = formatter.string(from: cutoffDate)

        cache.selectedByDayBucket = cache.selectedByDayBucket.filter { key, _ in
            let isoDate = String(key.prefix(10))
            return isoDate >= cutoffISO
        }

        if cache.usedByWeekBucket.count > 60 {
            let sortedKeys = cache.usedByWeekBucket.keys.sorted(by: >)
            cache.usedByWeekBucket = Dictionary(
                uniqueKeysWithValues: sortedKeys.prefix(60).compactMap { key in
                    guard let value = cache.usedByWeekBucket[key] else { return nil }
                    return (key, value)
                }
            )
        }
    }
}
