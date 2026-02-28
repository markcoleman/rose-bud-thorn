#if canImport(AppIntents)
import AppIntents
import Foundation

public struct CaptureMomentQuickActionIntent: AppIntent {
    public static var title: LocalizedStringResource = "Capture Moment"
    public static var description = IntentDescription("Launch a focused capture flow so you can quickly log your rose, bud, or thorn.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result(dialog: "Opening Rose, Bud, Thorn so you can capture this moment.")
    }
}

public struct CaptureRoseIntent: AppIntent {
    public static var title: LocalizedStringResource = "Capture Rose"

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result(dialog: "Open Rose, Bud, Thorn and add your rose for today.")
    }
}

public struct OpenTodayIntent: AppIntent {
    public static var title: LocalizedStringResource = "Open Today"

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result(dialog: "Open Rose, Bud, Thorn to today's capture.")
    }
}

public struct GenerateWeeklySummaryIntent: AppIntent {
    public static var title: LocalizedStringResource = "Generate Weekly Summary"

    public init() {}

    public func perform() async throws -> some IntentResult {
        .result(dialog: "Open the app and generate the latest weekly summary.")
    }
}

public struct RoseBudThornShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureMomentQuickActionIntent(),
            phrases: [
                "Capture moment in \(.applicationName)",
                "Log a reflection in \(.applicationName)",
                "Quick capture in \(.applicationName)"
            ],
            shortTitle: "Capture Moment",
            systemImageName: "bolt.badge.clock"
        )
        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: [
                "Open today's entry in \(.applicationName)"
            ],
            shortTitle: "Open Today",
            systemImageName: "sun.max"
        )
        AppShortcut(
            intent: GenerateWeeklySummaryIntent(),
            phrases: [
                "Generate weekly summary in \(.applicationName)"
            ],
            shortTitle: "Weekly Summary",
            systemImageName: "calendar.badge.clock"
        )
    }

    public static var shortcutTileColor: ShortcutTileColor {
        .orange
    }
}
#endif
