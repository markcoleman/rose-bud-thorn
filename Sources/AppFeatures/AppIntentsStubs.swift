#if canImport(AppIntents)
import AppIntents

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
#endif
