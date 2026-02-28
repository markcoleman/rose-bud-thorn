import Foundation
import CoreModels

#if canImport(UserNotifications)
@preconcurrency import UserNotifications

public actor ReminderScheduler {
    private let centerProvider: (() -> UNUserNotificationCenter)?

    public init(
        center: UNUserNotificationCenter? = nil,
        centerProvider: (() -> UNUserNotificationCenter)? = nil
    ) {
        if let center {
            self.centerProvider = { center }
        } else {
            self.centerProvider = centerProvider
        }
    }

    public static func live() -> ReminderScheduler {
        ReminderScheduler(centerProvider: { UNUserNotificationCenter.current() })
    }

    public func updateNotifications(
        for dayKey: LocalDayKey,
        isComplete: Bool,
        preferences: ReminderPreferences
    ) async {
        guard shouldAccessUserNotifications else {
            return
        }

        guard let center = centerProvider?() else {
            return
        }
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
        guard let center = centerProvider?() else {
            return
        }
        do {
            try await center.add(request)
        } catch {
            // No-op; reminders are best effort.
        }
    }

    private var shouldAccessUserNotifications: Bool {
        let env = ProcessInfo.processInfo.environment
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

        if env["XCTestConfigurationFilePath"] != nil {
            return false
        }

        if env.keys.contains(where: { $0.hasPrefix("XCTest") || $0.hasPrefix("SWIFT_TEST") }) {
            return false
        }

        if NSClassFromString("XCTestCase") != nil {
            return false
        }

        let bundlePath = Bundle.main.bundleURL.path
        if bundlePath.hasSuffix("/usr/bin") ||
            bundlePath.hasSuffix("/usr/bin/") ||
            bundlePath.contains("/usr/bin/") {
            return false
        }

        return true
    }
}
#else
public actor ReminderScheduler {
    public init() {}

    public static func live() -> ReminderScheduler {
        ReminderScheduler()
    }

    public func updateNotifications(
        for dayKey: LocalDayKey,
        isComplete: Bool,
        preferences: ReminderPreferences
    ) async {}
}
#endif
