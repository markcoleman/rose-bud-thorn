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
    public let completionTracker: EntryCompletionTracker
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
        let completionTracker = EntryCompletionTracker(entryStore: entryStore, dayCalculator: dayCalculator)

        self.entryRepository = entryRepository
        self.attachmentRepository = attachmentRepository
        self.searchIndex = searchIndex
        self.summaryService = summaryService
        self.entryStore = entryStore
        self.reminderPreferencesStore = reminderPreferencesStore
        self.reminderScheduler = reminderScheduler
        self.completionTracker = completionTracker
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
    static func defaultFeatureFlags() -> AppFeatureFlags {
        let env = ProcessInfo.processInfo.environment
        let processName = ProcessInfo.processInfo.processName.lowercased()

        let isTestProcess =
            env["XCTestConfigurationFilePath"] != nil ||
            processName.contains("xctest") ||
            processName.contains("swift-test") ||
            NSClassFromString("XCTestCase") != nil

        if isTestProcess {
            return AppFeatureFlags(remindersEnabled: false, streaksEnabled: true, widgetsEnabled: false)
        }

        return AppFeatureFlags()
    }
}
