import Foundation
import CoreModels
import CoreDate
import DocumentStore

public actor FileSearchIndex: SearchIndex {
    private let fileManager: FileManager
    private let layout: FileLayout
    private let writer: AtomicFileWriter
    private let dayCalculator: DayKeyCalculator
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let entryRepository: EntryRepository

    private var documents: [LocalDayKey: IndexDocument] = [:]
    private var isLoaded = false

    public init(
        configuration: DocumentStoreConfiguration,
        entryRepository: EntryRepository,
        fileManager: FileManager = .default,
        writer: AtomicFileWriter = AtomicFileWriter(),
        dayCalculator: DayKeyCalculator = DayKeyCalculator()
    ) throws {
        self.fileManager = fileManager
        self.layout = FileLayout(rootURL: configuration.rootURL)
        self.writer = writer
        self.dayCalculator = dayCalculator
        self.entryRepository = entryRepository

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        try layout.ensureBaseDirectories(using: fileManager)
    }

    public func upsert(_ entry: EntryDay) async throws {
        try await loadIfNeeded()
        documents[entry.dayKey] = IndexDocument(entry: entry)
        try persist()
    }

    public func remove(day: LocalDayKey) async throws {
        try await loadIfNeeded()
        documents.removeValue(forKey: day)
        try persist()
    }

    public func search(_ query: EntrySearchQuery) async throws -> [LocalDayKey] {
        try await loadIfNeeded()

        let normalizedText = query.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var results: [LocalDayKey] = []
        for (_, doc) in documents {
            if let hasPhoto = query.hasPhoto {
                if hasPhoto && doc.hasNoPhoto { continue }
                if !hasPhoto && doc.hasAnyPhoto { continue }
            }

            if let range = query.dateRange {
                guard let date = dayCalculator.date(for: doc.dayKey), range.contains(date) else {
                    continue
                }
            }

            if !normalizedText.isEmpty {
                let haystack = doc.text(for: query.categories).lowercased()
                guard haystack.contains(normalizedText) else {
                    continue
                }
            }

            results.append(doc.dayKey)
        }

        return results.sorted(by: >)
    }

    public func rebuildFromEntries() async throws {
        let days = try await entryRepository.list(range: nil)
        var rebuilt: [LocalDayKey: IndexDocument] = [:]
        rebuilt.reserveCapacity(days.count)

        for day in days {
            if let entry = try await entryRepository.load(day: day) {
                rebuilt[day] = IndexDocument(entry: entry)
            }
        }

        documents = rebuilt
        isLoaded = true
        try persist()
    }

    private func loadIfNeeded() async throws {
        guard !isLoaded else { return }

        let url = layout.indexFileURL
        guard fileManager.fileExists(atPath: url.path) else {
            documents = [:]
            isLoaded = true
            return
        }

        do {
            let data = try Data(contentsOf: url)
            documents = try decoder.decode([LocalDayKey: IndexDocument].self, from: data)
            isLoaded = true
        } catch {
            documents = [:]
            isLoaded = true
            try await rebuildFromEntries()
        }
    }

    private func persist() throws {
        let data = try encoder.encode(documents)
        try writer.write(data: data, to: layout.indexFileURL, fileManager: fileManager)
    }
}
