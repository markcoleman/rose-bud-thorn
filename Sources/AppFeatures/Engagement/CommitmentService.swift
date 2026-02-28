import Foundation
import DocumentStore

public actor CommitmentService {
    private let fileManager: FileManager
    private let layout: FileLayout
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(configuration: DocumentStoreConfiguration, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.layout = FileLayout(rootURL: configuration.rootURL)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load(for weekKey: String) throws -> WeeklyCommitment? {
        let url = commitmentURL(for: weekKey)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(WeeklyCommitment.self, from: data)
    }

    @discardableResult
    public func save(text: String, for weekKey: String) throws -> WeeklyCommitment? {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = commitmentURL(for: weekKey)

        guard !normalizedText.isEmpty else {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            return nil
        }

        let existing = try load(for: weekKey)
        let status = existing?.status ?? .planned
        let completedAt = status == .completed ? (existing?.completedAt ?? .now) : nil
        let commitment = WeeklyCommitment(
            weekKey: weekKey,
            text: normalizedText,
            status: status,
            updatedAt: .now,
            completedAt: completedAt
        )
        try persist(commitment)
        return commitment
    }

    @discardableResult
    public func markCompleted(for weekKey: String) throws -> WeeklyCommitment? {
        guard let existing = try load(for: weekKey) else {
            return nil
        }

        let commitment = WeeklyCommitment(
            weekKey: existing.weekKey,
            text: existing.text,
            status: .completed,
            updatedAt: .now,
            completedAt: existing.completedAt ?? .now
        )
        try persist(commitment)
        return commitment
    }

    private func persist(_ commitment: WeeklyCommitment) throws {
        let directory = layout.summaryDirectory(for: .week)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(commitment)
        try data.write(to: commitmentURL(for: commitment.weekKey), options: [.atomic])
    }

    private func commitmentURL(for weekKey: String) -> URL {
        layout.summaryDirectory(for: .week).appendingPathComponent("\(weekKey).commitment.json")
    }
}
