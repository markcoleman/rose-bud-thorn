import Foundation
import CoreDate
import CoreModels

public enum LocalAnalyticsEvent: String, CaseIterable, Codable, Sendable {
    case onboardingStarted = "onboarding_started"
    case onboardingRoseViewed = "onboarding_rose_viewed"
    case onboardingBudViewed = "onboarding_bud_viewed"
    case onboardingThornViewed = "onboarding_thorn_viewed"
    case onboardingAutoAdvanced = "onboarding_auto_advanced"
    case onboardingSkipped = "onboarding_skipped"
    case onboardingCompleted = "onboarding_completed"
    case onboardingReplayOpened = "onboarding_replay_opened"
    case todayScreenOpened = "today_screen_opened"
    case completionRingViewed = "completion_ring_viewed"
    case dailyEntryCompleted = "daily_entry_completed"
    case reminderPreferencesUpdated = "reminder_preferences_updated"
    case reminderScheduleEvaluated = "reminder_schedule_evaluated"
    case insightCardViewed = "insight_card_viewed"
    case insightCardTapped = "insight_card_tapped"
    case resurfacingViewed = "resurfacing_viewed"
    case resurfacingActioned = "resurfacing_actioned"
    case commitmentSaved = "commitment_saved"
    case commitmentCompleted = "commitment_completed"
    case summaryExportPreviewed = "summary_export_previewed"
    case summaryExportConfirmed = "summary_export_confirmed"
    case browseDayDetailsOpened = "browse_day_details_opened"
    case browseTimelineFastScrollUsed = "browse_timeline_fast_scroll_used"
    case browseTimelineQuickShareTapped = "browse_timeline_quick_share_tapped"
    case browseTimelineJumpToDateUsed = "browse_timeline_jump_to_date_used"
    case summaryDayDetailsOpened = "summary_day_details_opened"
    case daySharePromptShown = "day_share_prompt_shown"
    case dayShareInitiated = "day_share_initiated"
    case dayShareSent = "day_share_sent"
    case dayShareFailed = "day_share_failed"
}

public struct LocalAnalyticsSnapshot: Codable, Equatable, Sendable {
    public var totalCounts: [String: Int]
    public var dailyCounts: [String: [String: Int]]

    public init(
        totalCounts: [String: Int] = [:],
        dailyCounts: [String: [String: Int]] = [:]
    ) {
        self.totalCounts = totalCounts
        self.dailyCounts = dailyCounts
    }
}

public actor LocalAnalyticsStore {
    private let defaults: UserDefaults
    private let dayCalculator: DayKeyCalculator
    private let key = "LocalAnalyticsSnapshot.v1"
    private var snapshot: LocalAnalyticsSnapshot

    public init(
        defaults: UserDefaults = .standard,
        dayCalculator: DayKeyCalculator = DayKeyCalculator()
    ) {
        self.defaults = defaults
        self.dayCalculator = dayCalculator
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(LocalAnalyticsSnapshot.self, from: data) {
            self.snapshot = decoded
        } else {
            self.snapshot = LocalAnalyticsSnapshot()
        }
    }

    public func record(
        _ event: LocalAnalyticsEvent,
        count: Int = 1,
        at date: Date = .now,
        timeZone: TimeZone = .current
    ) {
        guard count > 0 else { return }
        let dayKey = dayCalculator.dayKey(for: date, timeZone: timeZone)
        increment(event, count: count, dayKey: dayKey)
    }

    @discardableResult
    public func recordOncePerDay(_ event: LocalAnalyticsEvent, dayKey: LocalDayKey) -> Bool {
        let token = dayToken(for: dayKey)
        let existing = snapshot.dailyCounts[event.rawValue]?[token] ?? 0
        guard existing == 0 else { return false }
        increment(event, count: 1, dayKey: dayKey)
        return true
    }

    public func totalCount(for event: LocalAnalyticsEvent) -> Int {
        snapshot.totalCounts[event.rawValue] ?? 0
    }

    public func dayCount(for event: LocalAnalyticsEvent, dayKey: LocalDayKey) -> Int {
        snapshot.dailyCounts[event.rawValue]?[dayToken(for: dayKey)] ?? 0
    }

    public func currentSnapshot() -> LocalAnalyticsSnapshot {
        snapshot
    }

    public func reset() {
        snapshot = LocalAnalyticsSnapshot()
        defaults.removeObject(forKey: key)
    }

    private func increment(_ event: LocalAnalyticsEvent, count: Int, dayKey: LocalDayKey) {
        snapshot.totalCounts[event.rawValue, default: 0] += count
        let token = dayToken(for: dayKey)
        var daily = snapshot.dailyCounts[event.rawValue] ?? [:]
        daily[token, default: 0] += count
        snapshot.dailyCounts[event.rawValue] = daily
        persist()
    }

    private func dayToken(for dayKey: LocalDayKey) -> String {
        "\(dayKey.isoDate)|\(dayKey.timeZoneID)"
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }
}
