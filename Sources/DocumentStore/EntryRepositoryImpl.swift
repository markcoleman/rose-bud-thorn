import Foundation
import CoreModels
import CoreDate

public actor EntryRepositoryImpl: EntryRepository {
    private let fileManager: FileManager
    private let layout: FileLayout
    private let writer: AtomicFileWriter
    private let coordinator: FileCoordinatorAdapter
    private let migrationManager: MigrationManager
    private let dayCalculator: DayKeyCalculator
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        configuration: DocumentStoreConfiguration,
        fileManager: FileManager = .default,
        writer: AtomicFileWriter = AtomicFileWriter(),
        coordinator: FileCoordinatorAdapter = FileCoordinatorAdapter(),
        migrationManager: MigrationManager = MigrationManager(),
        dayCalculator: DayKeyCalculator = DayKeyCalculator()
    ) throws {
        self.fileManager = fileManager
        self.layout = FileLayout(rootURL: configuration.rootURL)
        self.writer = writer
        self.coordinator = coordinator
        self.migrationManager = migrationManager
        self.dayCalculator = dayCalculator

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        try layout.ensureBaseDirectories(using: fileManager)
    }

    public func load(day: LocalDayKey) async throws -> EntryDay? {
        let url = layout.entryFileURL(for: day)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            return try coordinator.coordinateRead(at: url) { readURL in
                let data = try Data(contentsOf: readURL)
                let entry = try decoder.decode(EntryDay.self, from: data)
                try migrationManager.validate(entry: entry)
                return entry
            }
        } catch {
            throw DomainError.corruptEntry(day)
        }
    }

    public func save(_ entry: EntryDay) async throws {
        let url = layout.entryFileURL(for: entry.dayKey)
        let merged = try await mergeWithExistingIfNeeded(entry)
        let data = try encoder.encode(merged)

        do {
            try coordinator.coordinateWrite(at: url) { writeURL in
                try writer.write(data: data, to: writeURL, fileManager: fileManager)
            }
        } catch {
            throw DomainError.storageFailure("Failed to save \(entry.dayKey.isoDate): \(error.localizedDescription)")
        }
    }

    public func delete(day: LocalDayKey) async throws {
        let dayDirectory = layout.dayDirectory(for: day)
        guard fileManager.fileExists(atPath: dayDirectory.path) else { return }

        do {
            try fileManager.removeItem(at: dayDirectory)
        } catch {
            throw DomainError.storageFailure("Failed to delete day \(day.isoDate): \(error.localizedDescription)")
        }
    }

    public func list(range: DateInterval?) async throws -> [LocalDayKey] {
        let files = try entryFileURLs()
        var days: [LocalDayKey] = []

        for file in files {
            do {
                let data = try Data(contentsOf: file)
                let entry = try decoder.decode(EntryDay.self, from: data)
                try migrationManager.validate(entry: entry)

                if let range {
                    guard let date = dayCalculator.date(for: entry.dayKey), range.contains(date) else {
                        continue
                    }
                }

                days.append(entry.dayKey)
            } catch {
                continue
            }
        }

        return days.sorted(by: >)
    }

    public func allEntries() async throws -> [EntryDay] {
        let files = try entryFileURLs()
        var entries: [EntryDay] = []
        entries.reserveCapacity(files.count)

        for file in files {
            if let entry = try? decoder.decode(EntryDay.self, from: Data(contentsOf: file)) {
                try migrationManager.validate(entry: entry)
                entries.append(entry)
            }
        }

        return entries.sorted { $0.dayKey > $1.dayKey }
    }

    private func entryFileURLs() throws -> [URL] {
        let root = layout.entriesRoot
        guard fileManager.fileExists(atPath: root.path) else {
            return []
        }

        let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var files: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.lastPathComponent == "entry.json" else { continue }
            files.append(url)
        }

        return files
    }

    private func mergeWithExistingIfNeeded(_ incoming: EntryDay) async throws -> EntryDay {
        guard let existing = try await load(day: incoming.dayKey) else {
            return incoming
        }

        if existing == incoming {
            return incoming
        }

        let merged = merge(existing: existing, incoming: incoming)
        try archiveConflict(existing: existing, incoming: incoming, merged: merged)
        return merged
    }

    private func merge(existing: EntryDay, incoming: EntryDay) -> EntryDay {
        var merged = incoming

        merged.roseItem = latest(existing.roseItem, incoming.roseItem)
        merged.budItem = latest(existing.budItem, incoming.budItem)
        merged.thornItem = latest(existing.thornItem, incoming.thornItem)

        merged.tags = Array(Set(existing.tags).union(incoming.tags)).sorted()

        if merged.mood == nil {
            merged.mood = existing.mood
        }

        merged.favorite = existing.favorite || incoming.favorite

        let created = min(existing.createdAt, incoming.createdAt)
        let updated = max(existing.updatedAt, incoming.updatedAt)

        return EntryDay(
            schemaVersion: max(existing.schemaVersion, incoming.schemaVersion),
            dayKey: incoming.dayKey,
            roseItem: merged.roseItem,
            budItem: merged.budItem,
            thornItem: merged.thornItem,
            tags: merged.tags,
            mood: merged.mood,
            favorite: merged.favorite,
            createdAt: created,
            updatedAt: updated
        )
    }

    private func latest(_ lhs: EntryItem, _ rhs: EntryItem) -> EntryItem {
        lhs.updatedAt >= rhs.updatedAt ? lhs : rhs
    }

    private func archiveConflict(existing: EntryDay, incoming: EntryDay, merged: EntryDay) throws {
        let dayFolder = layout.conflictsRoot.appendingPathComponent(existing.dayKey.isoDate, isDirectory: true)
        try fileManager.createDirectory(at: dayFolder, withIntermediateDirectories: true)

        struct ConflictRecord: Codable {
            let existing: EntryDay
            let incoming: EntryDay
            let merged: EntryDay
            let archivedAt: Date
        }

        let record = ConflictRecord(existing: existing, incoming: incoming, merged: merged, archivedAt: .now)
        let data = try encoder.encode(record)
        let fileName = "\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString).json"
        let destination = dayFolder.appendingPathComponent(fileName)
        try writer.write(data: data, to: destination, fileManager: fileManager)
    }
}
