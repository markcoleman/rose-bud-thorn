import Foundation
import CoreModels
import CoreDate
import DocumentStore
import SearchIndex
import Summaries

public struct AppEnvironment: Sendable {
    public let configuration: DocumentStoreConfiguration
    public let dayCalculator: DayKeyCalculator
    public let periodCalculator: PeriodKeyCalculator
    public let entryRepository: EntryRepositoryImpl
    public let attachmentRepository: AttachmentRepositoryImpl
    public let searchIndex: FileSearchIndex
    public let summaryService: SummaryServiceImpl
    public let entryStore: EntryStore
    public let reminderPreferencesStore: ReminderPreferencesStore
    public let reminderScheduler: ReminderScheduler
    public let promptPreferencesStore: PromptPreferencesStore
    public let promptSelector: PromptSelector
    public let weeklyIntentionStore: WeeklyIntentionStore
    public let completionTracker: EntryCompletionTracker
    public let analyticsStore: LocalAnalyticsStore
    public let featureFlags: AppFeatureFlags

    public init(configuration: DocumentStoreConfiguration) throws {
        self.configuration = configuration
        self.dayCalculator = DayKeyCalculator()
        self.periodCalculator = PeriodKeyCalculator()
        let featureFlags = Self.defaultFeatureFlags()

        let entryRepository = try EntryRepositoryImpl(configuration: configuration)
        let attachmentRepository = try AttachmentRepositoryImpl(configuration: configuration)
        let searchIndex = try FileSearchIndex(configuration: configuration, entryRepository: entryRepository)
        let summaryService = try SummaryServiceImpl(configuration: configuration, entryRepository: entryRepository)
        let entryStore = EntryStore(entries: entryRepository, attachments: attachmentRepository, index: searchIndex)
        let reminderPreferencesStore = ReminderPreferencesStore()
        let reminderScheduler = featureFlags.remindersEnabled ? ReminderScheduler.live() : ReminderScheduler()
        let promptPreferencesStore = PromptPreferencesStore()
        let promptSelector = PromptSelector(preferencesStore: promptPreferencesStore)
        let weeklyIntentionStore = WeeklyIntentionStore(configuration: configuration)
        let completionTracker = EntryCompletionTracker(entryStore: entryStore, dayCalculator: dayCalculator)
        let analyticsDefaults = Self.analyticsDefaults()
        let analyticsStore = LocalAnalyticsStore(defaults: analyticsDefaults, dayCalculator: dayCalculator)

        self.entryRepository = entryRepository
        self.attachmentRepository = attachmentRepository
        self.searchIndex = searchIndex
        self.summaryService = summaryService
        self.entryStore = entryStore
        self.reminderPreferencesStore = reminderPreferencesStore
        self.reminderScheduler = reminderScheduler
        self.promptPreferencesStore = promptPreferencesStore
        self.promptSelector = promptSelector
        self.weeklyIntentionStore = weeklyIntentionStore
        self.completionTracker = completionTracker
        self.analyticsStore = analyticsStore
        self.featureFlags = featureFlags
    }

    public static func live() throws -> AppEnvironment {
        try AppEnvironment(configuration: .live())
    }

    public func photoURL(for ref: PhotoRef, day: LocalDayKey) -> URL {
        let layout = FileLayout(rootURL: configuration.rootURL)
        return layout.dayDirectory(for: day).appendingPathComponent(ref.relativePath)
    }

    public func videoURL(for ref: VideoRef, day: LocalDayKey) -> URL {
        let layout = FileLayout(rootURL: configuration.rootURL)
        return layout.dayDirectory(for: day).appendingPathComponent(ref.relativePath)
    }

    public func summaryMarkdownURL(period: SummaryPeriod, key: String) -> URL {
        let layout = FileLayout(rootURL: configuration.rootURL)
        return layout.summaryMarkdownURL(period: period, key: key)
    }
}

private extension AppEnvironment {
    static var isTestProcess: Bool {
        let env = ProcessInfo.processInfo.environment
        let processName = ProcessInfo.processInfo.processName.lowercased()

        return env["XCTestConfigurationFilePath"] != nil ||
            processName.contains("xctest") ||
            processName.contains("swift-test") ||
            NSClassFromString("XCTestCase") != nil
    }

    static func analyticsDefaults() -> UserDefaults {
        guard isTestProcess else {
            return .standard
        }
        return UserDefaults(suiteName: "LocalAnalyticsStore.Tests.\(UUID().uuidString)") ?? .standard
    }

    static func defaultFeatureFlags() -> AppFeatureFlags {
        if isTestProcess {
            return AppFeatureFlags(remindersEnabled: false, streaksEnabled: true, widgetsEnabled: false)
        }

        return AppFeatureFlags()
    }
}
