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

    public init(configuration: DocumentStoreConfiguration) throws {
        self.configuration = configuration
        self.dayCalculator = DayKeyCalculator()
        self.periodCalculator = PeriodKeyCalculator()

        let entryRepository = try EntryRepositoryImpl(configuration: configuration)
        let attachmentRepository = try AttachmentRepositoryImpl(configuration: configuration)
        let searchIndex = try FileSearchIndex(configuration: configuration, entryRepository: entryRepository)
        let summaryService = try SummaryServiceImpl(configuration: configuration, entryRepository: entryRepository)
        let entryStore = EntryStore(entries: entryRepository, attachments: attachmentRepository, index: searchIndex)

        self.entryRepository = entryRepository
        self.attachmentRepository = attachmentRepository
        self.searchIndex = searchIndex
        self.summaryService = summaryService
        self.entryStore = entryStore
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
