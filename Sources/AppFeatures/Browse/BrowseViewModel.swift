import Foundation
import Observation
import CoreModels
import CoreDate

@MainActor
@Observable
public final class BrowseViewModel {
    public var days: [LocalDayKey] = []
    public var snapshots: [BrowseDaySnapshot] = []
    public var sections: [BrowseMonthSection] = []
    public var availableYears: [String] = []
    public var selectedYear: String?
    public var quickFilter: BrowseQuickFilter = .all
    public var selectedDate: Date = .now
    public var errorMessage: String?
    public var isLoading = false

    public let environment: AppEnvironment
    private let dayCalculator: DayKeyCalculator
    private let nowProvider: () -> Date
    private var snapshotCache: [LocalDayKey: BrowseDaySnapshot] = [:]
    private var daySet: Set<LocalDayKey> = []
    private var monthDayLookup: [String: Set<Int>] = [:]
    private var hasLoadedSnapshots = false

    public init(environment: AppEnvironment, nowProvider: @escaping () -> Date = { .now }) {
        self.environment = environment
        self.dayCalculator = environment.dayCalculator
        self.nowProvider = nowProvider
    }

    public func loadSnapshots(forceReload: Bool = false) async {
        if forceReload {
            invalidateSnapshotCache()
        }

        isLoading = true
        defer { isLoading = false }

        do {
            days = try await environment.entryStore.list(range: nil)
            daySet = Set(days)

            if let first = days.first, let date = dayCalculator.date(for: first) {
                selectedDate = date
            }

            try await loadMissingSnapshots(for: days)
            snapshots = days.compactMap { snapshotCache[$0] }
            availableYears = Array(Set(snapshots.map(\.dayKey.year))).sorted(by: >)
            if let selectedYear, !availableYears.contains(selectedYear) {
                self.selectedYear = nil
            }
            rebuildMonthLookup()
            applyFilter()
            errorMessage = nil
            hasLoadedSnapshots = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refreshSnapshots() async {
        await loadSnapshots(forceReload: true)
    }

    public func reloadOnForegroundIfNeeded() async {
        guard hasLoadedSnapshots else { return }
        await loadSnapshots(forceReload: true)
    }

    public func invalidateSnapshotCache() {
        snapshotCache = [:]
        snapshots = []
        sections = []
        availableYears = []
        monthDayLookup = [:]
        hasLoadedSnapshots = false
    }

    public func setQuickFilter(_ filter: BrowseQuickFilter) {
        quickFilter = filter
        if filter == .thisMonth {
            selectedYear = dayCalculator.dayKey(for: nowProvider(), timeZone: .current).year
        } else if filter == .onThisDay {
            selectedYear = nil
        }
        applyFilter()
    }

    public func setSelectedYear(_ year: String?) {
        selectedYear = year
        applyFilter()
    }

    public func applyFilter() {
        var filtered = snapshots
        let today = dayCalculator.dayKey(for: nowProvider(), timeZone: .current)

        switch quickFilter {
        case .all:
            break
        case .favorites:
            filtered = filtered.filter(\.favorite)
        case .media:
            filtered = filtered.filter(\.hasMedia)
        case .thisMonth:
            filtered = filtered.filter { $0.dayKey.year == today.year && $0.dayKey.month == today.month }
        case .onThisDay:
            filtered = filtered.filter {
                $0.dayKey.day == today.day &&
                $0.dayKey.month == today.month &&
                $0.dayKey.isoDate < today.isoDate
            }
        }

        if quickFilter != .onThisDay, let selectedYear {
            filtered = filtered.filter { $0.dayKey.year == selectedYear }
        }

        sections = groupedSections(from: filtered)
    }

    public func firstMonthKey(forYear year: String?) -> String? {
        guard let year else { return sections.first?.monthKey }
        return sections.first(where: { $0.monthKey.hasPrefix(year + "-") })?.monthKey
    }

    public func dayKey(for date: Date) -> LocalDayKey {
        dayCalculator.dayKey(for: date)
    }

    public func date(for dayKey: LocalDayKey) -> Date? {
        dayCalculator.date(for: dayKey)
    }

    public func hasEntry(for dayKey: LocalDayKey) -> Bool {
        daySet.contains(dayKey)
    }

    public func entryDayNumbers(inMonthContaining date: Date) -> Set<Int> {
        monthDayLookup[monthKey(for: date)] ?? []
    }

    public func previousEntry(before dayKey: LocalDayKey?) -> LocalDayKey? {
        guard let dayKey else { return days.dropFirst().first }
        guard let index = days.firstIndex(of: dayKey), index + 1 < days.count else { return nil }
        return days[index + 1]
    }

    public func nextEntry(after dayKey: LocalDayKey?) -> LocalDayKey? {
        guard let dayKey else { return days.first }
        guard let index = days.firstIndex(of: dayKey), index > 0 else { return nil }
        return days[index - 1]
    }

    public func nearestEntry(to date: Date) -> LocalDayKey? {
        let candidate = dayKey(for: date)
        if daySet.contains(candidate) {
            return candidate
        }

        guard !days.isEmpty else {
            return nil
        }

        if let closest = days.min(by: { abs(dayDistance($0, to: candidate)) < abs(dayDistance($1, to: candidate)) }) {
            return closest
        }

        return days.first
    }

    public func monthTitle(for monthKey: String) -> String {
        Self.monthTitle(monthKey: monthKey)
    }

    private func loadMissingSnapshots(for days: [LocalDayKey]) async throws {
        let missing = days.filter { snapshotCache[$0] == nil }
        guard !missing.isEmpty else { return }

        let batchSize = 20
        let entryStore = environment.entryStore
        var index = 0

        while index < missing.count {
            let endIndex = min(index + batchSize, missing.count)
            let batch = Array(missing[index..<endIndex])
            var loaded: [BrowseDaySnapshot] = []
            loaded.reserveCapacity(batch.count)

            await withTaskGroup(of: BrowseDaySnapshot?.self) { group in
                for day in batch {
                    group.addTask {
                        do {
                            let entry = try await entryStore.load(day: day)
                            return BrowseDaySnapshot(entry: entry)
                        } catch {
                            return nil
                        }
                    }
                }

                for await snapshot in group {
                    if let snapshot {
                        loaded.append(snapshot)
                    }
                }
            }

            for snapshot in loaded {
                snapshotCache[snapshot.dayKey] = snapshot
            }

            index += batchSize
        }
    }

    private func groupedSections(from items: [BrowseDaySnapshot]) -> [BrowseMonthSection] {
        let grouped = Dictionary(grouping: items, by: \.dayKey.monthKey)
        return grouped
            .map { monthKey, days in
                BrowseMonthSection(
                    monthKey: monthKey,
                    title: Self.monthTitle(monthKey: monthKey),
                    days: days.sorted { $0.dayKey > $1.dayKey }
                )
            }
            .sorted { $0.monthKey > $1.monthKey }
    }

    private func rebuildMonthLookup() {
        monthDayLookup = snapshots.reduce(into: [String: Set<Int>]()) { partialResult, snapshot in
            partialResult[snapshot.dayKey.monthKey, default: []].insert(snapshot.dayKey.dayInt)
        }
    }

    private func dayDistance(_ lhs: LocalDayKey, to rhs: LocalDayKey) -> Int {
        guard let lhsDate = dayCalculator.date(for: lhs),
              let rhsDate = dayCalculator.date(for: rhs) else {
            return Int.max / 2
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: lhs.timeZoneID) ?? .current
        return calendar.dateComponents([.day], from: lhsDate, to: rhsDate).day ?? Int.max / 2
    }

    private func monthKey(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        return String(format: "%04d-%02d", year, month)
    }

    private static func monthTitle(monthKey: String) -> String {
        let parts = monthKey.split(separator: "-")
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else {
            return monthKey
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = DateComponents(year: year, month: month, day: 1)
        guard let date = calendar.date(from: components) else {
            return monthKey
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}
