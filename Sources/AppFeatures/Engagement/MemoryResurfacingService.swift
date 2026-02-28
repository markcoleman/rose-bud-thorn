import Foundation
import CoreModels
import CoreDate
import DocumentStore

public actor MemoryResurfacingService {
    private struct DecisionEnvelope: Codable, Sendable {
        var decisions: [String: ResurfacingDecision]
    }

    private let entryStore: EntryStore
    private let dayCalculator: DayKeyCalculator
    private let layout: FileLayout
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        configuration: DocumentStoreConfiguration,
        entryStore: EntryStore,
        dayCalculator: DayKeyCalculator = DayKeyCalculator(),
        fileManager: FileManager = .default
    ) {
        self.entryStore = entryStore
        self.dayCalculator = dayCalculator
        self.layout = FileLayout(rootURL: configuration.rootURL)
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func memories(
        for referenceDate: Date = .now,
        timeZone: TimeZone = .current,
        limit: Int = 3
    ) async throws -> [ResurfacedMemory] {
        guard limit > 0 else {
            return []
        }

        let today = dayCalculator.dayKey(for: referenceDate, timeZone: timeZone)
        let decisions = try loadDecisions()
        let allDayKeys = try await entryStore.list(range: nil).sorted(by: >)
        var memories: [ResurfacedMemory] = []
        memories.reserveCapacity(limit)

        for dayKey in allDayKeys {
            guard dayKey.isoDate < today.isoDate else { continue }
            guard dayKey.month == today.month, dayKey.day == today.day else { continue }

            let entry = try await entryStore.load(day: dayKey)
            for type in EntryType.allCases {
                guard let excerpt = memoryExcerpt(from: entry.item(for: type)) else { continue }
                let memoryID = memoryIdentifier(dayKey: dayKey, type: type)

                if let decision = decisions[memoryID], decision.cooldownUntil.isoDate >= today.isoDate {
                    continue
                }

                memories.append(
                    ResurfacedMemory(
                        id: memoryID,
                        sourceDayKey: dayKey,
                        type: type,
                        excerpt: excerpt,
                        thenVsNowPrompt: "Then vs now: What's different since \(dayKey.isoDate)?"
                    )
                )
                break
            }

            if memories.count == limit {
                break
            }
        }

        return memories
    }

    @discardableResult
    public func record(
        decisionAction: ResurfacingAction,
        for memory: ResurfacedMemory,
        referenceDate: Date = .now,
        timeZone: TimeZone = .current
    ) throws -> ResurfacingDecision {
        var decisions = try loadDecisions()
        let cooldownDays: Int

        switch decisionAction {
        case .dismiss:
            cooldownDays = 30
        case .snooze:
            cooldownDays = 7
        }

        let cooldownDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: cooldownDays, to: referenceDate) ?? referenceDate
        let cooldownUntil = dayCalculator.dayKey(for: cooldownDate, timeZone: timeZone)
        let decision = ResurfacingDecision(
            memoryID: memory.id,
            sourceDayKey: memory.sourceDayKey,
            action: decisionAction,
            decidedAt: referenceDate,
            cooldownUntil: cooldownUntil
        )
        decisions[memory.id] = decision
        try save(decisions: decisions)
        return decision
    }

    private func memoryExcerpt(from item: EntryItem) -> String? {
        let short = item.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !short.isEmpty {
            return short
        }

        let journal = item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return String(journal.prefix(160))
        }

        return nil
    }

    private func memoryIdentifier(dayKey: LocalDayKey, type: EntryType) -> String {
        "\(dayKey.isoDate)|\(dayKey.timeZoneID)|\(type.rawValue)"
    }

    private func decisionsURL() -> URL {
        layout.summariesRoot
            .appendingPathComponent("resurfacing", isDirectory: true)
            .appendingPathComponent("decisions.json")
    }

    private func loadDecisions() throws -> [String: ResurfacingDecision] {
        let url = decisionsURL()
        guard fileManager.fileExists(atPath: url.path) else {
            return [:]
        }

        let data = try Data(contentsOf: url)
        let envelope = try decoder.decode(DecisionEnvelope.self, from: data)
        return envelope.decisions
    }

    private func save(decisions: [String: ResurfacingDecision]) throws {
        let url = decisionsURL()
        let directory = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(DecisionEnvelope(decisions: decisions))
        try data.write(to: url, options: [.atomic])
    }
}
