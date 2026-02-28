import Foundation
import CoreModels

#if canImport(UserNotifications)
import UserNotifications

public actor ReminderScheduler {
    private let center: UNUserNotificationCenter?

    public init(center: UNUserNotificationCenter? = nil) {
        self.center = center
    }

    public func updateNotifications(
        for dayKey: LocalDayKey,
        isComplete: Bool,
        preferences: ReminderPreferences
    ) async {
        guard !isRunningTests else {
            return
        }

        let center = notificationCenter
        let identifiers = identifiers(for: dayKey)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        guard preferences.isEnabled, !isComplete else {
            return
        }

        if !preferences.includeWeekends, isWeekend(dayKey: dayKey) {
            return
        }

        let _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])

        let reminder = makeReminderRequest(
            identifier: identifiers[0],
            title: "Rose, Bud, Thorn",
            body: "Your daily reflection is still open.",
            dayKey: dayKey,
            hour: preferences.startHour
        )

        await submit(reminder)

        guard preferences.allowsEndOfDayFallback, preferences.endHour != preferences.startHour else {
            return
        }

        let fallback = makeReminderRequest(
            identifier: identifiers[1],
            title: "Before the day ends",
            body: "Capture one quick thought for today.",
            dayKey: dayKey,
            hour: preferences.endHour
        )
        await submit(fallback)
    }

    private func identifiers(for dayKey: LocalDayKey) -> [String] {
        ["daily-primary-\(dayKey.isoDate)", "daily-fallback-\(dayKey.isoDate)"]
    }

    private func makeReminderRequest(
        identifier: String,
        title: String,
        body: String,
        dayKey: LocalDayKey,
        hour: Int
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["day": dayKey.isoDate]

        var components = dateComponents(for: dayKey)
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func dateComponents(for dayKey: LocalDayKey) -> DateComponents {
        let segments = dayKey.isoDate.split(separator: "-")
        let year = Int(segments.first ?? "")
        let month = segments.count > 1 ? Int(segments[1]) : nil
        let day = segments.count > 2 ? Int(segments[2]) : nil

        let timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        return DateComponents(timeZone: timeZone, year: year, month: month, day: day)
    }

    private func isWeekend(dayKey: LocalDayKey) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        guard let date = calendar.date(from: dateComponents(for: dayKey)) else {
            return false
        }
        return calendar.isDateInWeekend(date)
    }

    private func submit(_ request: UNNotificationRequest) async {
        let center = notificationCenter
        do {
            try await center.add(request)
        } catch {
            // No-op; reminders are best effort.
        }
    }

    private var notificationCenter: UNUserNotificationCenter {
        center ?? UNUserNotificationCenter.current()
    }

        let processName = ProcessInfo.processInfo.processName.lowercased()
        let executablePath = (ProcessInfo.processInfo.arguments.first ?? "").lowercased()
        let bundleIdentifier = Bundle.main.bundleIdentifier

        if processName.contains("xctest") || processName.contains("swift-test") {
            return false
        }

        if executablePath.contains("/usr/bin/") {
            return false
        }
        if bundleIdentifier == nil {
            return false
        }

        if bundlePath.hasSuffix("/usr/bin") ||
            bundlePath.hasSuffix("/usr/bin/") ||
            bundlePath.contains("/usr/bin/") {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
#else
public actor ReminderScheduler {
    public init() {}

    public func updateNotifications(
        for dayKey: LocalDayKey,
        isComplete: Bool,
        preferences: ReminderPreferences
    ) async {}
}
#endif
