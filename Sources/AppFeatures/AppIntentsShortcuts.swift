#if canImport(AppIntents)
import AppIntents
import Foundation

public protocol DeepLinkLaunchingIntent: AppIntent {
    static var deepLink: URL { get }
    static var successDialog: IntentDialog { get }
}

extension DeepLinkLaunchingIntent {
    public static var openAppWhenRun: Bool { true }

    public func perform() async throws -> some IntentResult {
        if UserDefaults.standard.bool(forKey: PrivacyLockManager.enabledDefaultsKey) {
            IntentLaunchStore.clear()
            return .result(dialog: IntentDialog("Privacy lock is enabled. Unlock the app to continue."))
        }

        IntentLaunchStore.queueDeepLink(Self.deepLink)
        return .result(dialog: Self.successDialog)
    }
}

public struct CaptureMomentQuickActionIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Capture Moment"
    public static let description = IntentDescription("Open quick capture in Rose, Bud, Thorn.")
    public static let deepLink = URL(string: "rosebudthorn://today?source=intent")!
    public static let successDialog = IntentDialog("Opening quick capture in Rose, Bud, Thorn.")

    public init() {}
}

public struct CaptureRoseIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Log a Rose"
    public static let description = IntentDescription("Open directly to today's Rose capture.")
    public static let deepLink = URL(string: "rosebudthorn://capture?type=rose&source=intent")!
    public static let successDialog = IntentDialog("Opening Rose capture.")

    public init() {}
}

public struct CaptureBudIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Log a Bud"
    public static let description = IntentDescription("Open directly to today's Bud capture.")
    public static let deepLink = URL(string: "rosebudthorn://capture?type=bud&source=intent")!
    public static let successDialog = IntentDialog("Opening Bud capture.")

    public init() {}
}

public struct CaptureThornIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Log a Thorn"
    public static let description = IntentDescription("Open directly to today's Thorn capture.")
    public static let deepLink = URL(string: "rosebudthorn://capture?type=thorn&source=intent")!
    public static let successDialog = IntentDialog("Opening Thorn capture.")

    public init() {}
}

public struct OpenTodayIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Open Today"
    public static let description = IntentDescription("Open today's entry.")
    public static let deepLink = URL(string: "rosebudthorn://today?source=intent")!
    public static let successDialog = IntentDialog("Opening today's entry.")

    public init() {}
}

public struct OpenWeeklySummaryIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Open Weekly Summary"
    public static let description = IntentDescription("Open the current weekly summary.")
    public static let deepLink = URL(string: "rosebudthorn://summary?period=week&action=open-current&source=intent")!
    public static let successDialog = IntentDialog("Opening this week's summary.")

    public init() {}
}

public struct StartWeeklyReviewIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Start Weekly Review"
    public static let description = IntentDescription("Open the guided weekly review ritual.")
    public static let deepLink = URL(string: "rosebudthorn://weekly-review?source=intent")!
    public static let successDialog = IntentDialog("Opening weekly review.")

    public init() {}
}

public struct OpenEngagementHubIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Open Engagement Hub"
    public static let description = IntentDescription("Open today's Engagement Hub with insights and resurfaced memories.")
    public static let deepLink = URL(string: "rosebudthorn://engagement?source=intent")!
    public static let successDialog = IntentDialog("Opening Engagement Hub.")

    public init() {}
}

public struct OpenOnThisDayIntent: DeepLinkLaunchingIntent {
    public static let title: LocalizedStringResource = "Open On This Day"
    public static let description = IntentDescription("Open today's resurfaced memory module.")
    public static let deepLink = URL(string: "rosebudthorn://on-this-day?source=intent")!
    public static let successDialog = IntentDialog("Opening On This Day.")

    public init() {}
}

public struct RoseBudThornShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureRoseIntent(),
            phrases: [
                "Log a rose in \(.applicationName)",
                "Capture rose in \(.applicationName)"
            ],
            shortTitle: "Log a Rose",
            systemImageName: "sun.max"
        )
        AppShortcut(
            intent: CaptureBudIntent(),
            phrases: [
                "Log a bud in \(.applicationName)",
                "Capture bud in \(.applicationName)"
            ],
            shortTitle: "Log a Bud",
            systemImageName: "leaf"
        )
        AppShortcut(
            intent: CaptureThornIntent(),
            phrases: [
                "Log a thorn in \(.applicationName)",
                "Capture thorn in \(.applicationName)"
            ],
            shortTitle: "Log a Thorn",
            systemImageName: "exclamationmark.triangle"
        )
        AppShortcut(
            intent: OpenWeeklySummaryIntent(),
            phrases: [
                "Open weekly summary in \(.applicationName)"
            ],
            shortTitle: "Weekly Summary",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: StartWeeklyReviewIntent(),
            phrases: [
                "Start weekly review in \(.applicationName)"
            ],
            shortTitle: "Weekly Review",
            systemImageName: "checklist"
        )
        AppShortcut(
            intent: OpenEngagementHubIntent(),
            phrases: [
                "Open engagement hub in \(.applicationName)"
            ],
            shortTitle: "Engagement Hub",
            systemImageName: "bolt.heart"
        )
        AppShortcut(
            intent: OpenOnThisDayIntent(),
            phrases: [
                "Open on this day in \(.applicationName)"
            ],
            shortTitle: "On This Day",
            systemImageName: "clock.arrow.circlepath"
        )
    }

    public static var shortcutTileColor: ShortcutTileColor {
        .orange
    }
}
#endif
