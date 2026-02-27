import Foundation
import CoreModels
import CoreDate
import DocumentStore

public actor SummaryServiceImpl: SummaryService {
    private let entryRepository: EntryRepository
    private let fileManager: FileManager
    private let layout: FileLayout
    private let writer: AtomicFileWriter
    private let periodCalculator: PeriodKeyCalculator
    private let highlightExtractor: HighlightExtractor
    private let renderer: SummaryMarkdownRenderer
    private let migrationManager: MigrationManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        configuration: DocumentStoreConfiguration,
        entryRepository: EntryRepository,
        fileManager: FileManager = .default,
        writer: AtomicFileWriter = AtomicFileWriter(),
        periodCalculator: PeriodKeyCalculator = PeriodKeyCalculator(),
        highlightExtractor: HighlightExtractor = HighlightExtractor(),
        renderer: SummaryMarkdownRenderer = SummaryMarkdownRenderer(),
        migrationManager: MigrationManager = MigrationManager()
    ) throws {
        self.entryRepository = entryRepository
        self.fileManager = fileManager
        self.layout = FileLayout(rootURL: configuration.rootURL)
        self.writer = writer
        self.periodCalculator = periodCalculator
        self.highlightExtractor = highlightExtractor
        self.renderer = renderer
        self.migrationManager = migrationManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        try layout.ensureBaseDirectories(using: fileManager)
    }

    public func generate(period: SummaryPeriod, key: String) async throws -> SummaryArtifact {
        guard let range = periodCalculator.range(for: period, key: key) else {
            throw DomainError.summaryFailure("Invalid period key: \(key)")
        }

        let dayKeys = try await entryRepository.list(range: range)
        var entries: [EntryDay] = []
        entries.reserveCapacity(dayKeys.count)

        for dayKey in dayKeys {
            if let entry = try await entryRepository.load(day: dayKey) {
                entries.append(entry)
            }
        }

        entries.sort { $0.dayKey < $1.dayKey }

        let highlights = highlightExtractor.extract(from: entries)
        let quotes = extractNotableQuotes(from: entries)
        let photoRefs = entries
            .flatMap { [$0.roseItem.photos, $0.budItem.photos, $0.thornItem.photos].flatMap { $0 } }
            .prefix(12)
        let generatedAt = Date()

        let markdown = renderer.render(
            period: period,
            key: key,
            generatedAt: generatedAt,
            entries: entries,
            highlights: highlights,
            quotes: quotes,
            photoRefs: Array(photoRefs)
        )

        let artifact = SummaryArtifact(
            period: period,
            key: key,
            generatedAt: generatedAt,
            contentMarkdown: markdown,
            highlights: highlights,
            photoRefs: Array(photoRefs)
        )

        try persist(artifact)
        return artifact
    }

    public func load(period: SummaryPeriod, key: String) async throws -> SummaryArtifact? {
        let metadataURL = layout.summaryMetadataURL(period: period, key: key)
        if fileManager.fileExists(atPath: metadataURL.path) {
            let data = try Data(contentsOf: metadataURL)
            let artifact = try decoder.decode(SummaryArtifact.self, from: data)
            try migrationManager.validate(summary: artifact)
            return artifact
        }

        let markdownURL = layout.summaryMarkdownURL(period: period, key: key)
        guard fileManager.fileExists(atPath: markdownURL.path) else {
            return nil
        }

        let markdown = try String(contentsOf: markdownURL)
        let generatedAt = (try? fileManager.attributesOfItem(atPath: markdownURL.path)[.modificationDate] as? Date) ?? .now

        return SummaryArtifact(
            period: period,
            key: key,
            generatedAt: generatedAt,
            contentMarkdown: markdown,
            highlights: [],
            photoRefs: []
        )
    }

    public func list(period: SummaryPeriod) async throws -> [SummaryArtifact] {
        let directory = layout.summaryDirectory(for: period)
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let urls = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let keys = Set(urls.map { $0.deletingPathExtension().lastPathComponent })
        var artifacts: [SummaryArtifact] = []
        artifacts.reserveCapacity(keys.count)

        for key in keys {
            if let artifact = try await load(period: period, key: key) {
                artifacts.append(artifact)
            }
        }

        return artifacts.sorted { $0.key > $1.key }
    }

    public func summaryMarkdownURL(period: SummaryPeriod, key: String) -> URL {
        layout.summaryMarkdownURL(period: period, key: key)
    }

    private func persist(_ artifact: SummaryArtifact) throws {
        let markdownDirectory = layout.summaryDirectory(for: artifact.period)
        try fileManager.createDirectory(at: markdownDirectory, withIntermediateDirectories: true)

        let markdownURL = layout.summaryMarkdownURL(period: artifact.period, key: artifact.key)
        let metadataURL = layout.summaryMetadataURL(period: artifact.period, key: artifact.key)

        let markdownData = Data(artifact.contentMarkdown.utf8)
        let metadataData = try encoder.encode(artifact)

        try writer.write(data: markdownData, to: markdownURL, fileManager: fileManager)
        try writer.write(data: metadataData, to: metadataURL, fileManager: fileManager)
    }

    private func extractNotableQuotes(from entries: [EntryDay]) -> [String] {
        var quotes: [String] = []
        for entry in entries {
            for type in EntryType.allCases {
                let text = entry.item(for: type).journalTextMarkdown
                guard !text.isEmpty else { continue }
                if let sentence = firstSentence(from: text) {
                    quotes.append(sentence)
                }
            }
        }
        return Array(quotes.prefix(5))
    }

    private func firstSentence(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let range = trimmed.range(of: ".") {
            let sentence = String(trimmed[..<range.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                return sentence
            }
        }

        return String(trimmed.prefix(120))
    }
}
