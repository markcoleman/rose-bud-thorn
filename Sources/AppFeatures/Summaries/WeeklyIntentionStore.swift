import Foundation
import DocumentStore

public struct WeeklyIntention: Codable, Equatable, Sendable {
    public let weekKey: String
    public let text: String
    public let updatedAt: Date

    public init(weekKey: String, text: String, updatedAt: Date = .now) {
        self.weekKey = weekKey
        self.text = text
        self.updatedAt = updatedAt
    }
}

public actor WeeklyIntentionStore {
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

    public func load(for weekKey: String) throws -> WeeklyIntention? {
        let url = intentionURL(for: weekKey)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(WeeklyIntention.self, from: data)
    }

    public func save(text: String, for weekKey: String) throws {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = intentionURL(for: weekKey)

        if normalizedText.isEmpty {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
            return
        }

        let directory = layout.summaryDirectory(for: .week)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let payload = WeeklyIntention(weekKey: weekKey, text: normalizedText, updatedAt: .now)
        let data = try encoder.encode(payload)
        try data.write(to: url, options: [.atomic])
    }

    private func intentionURL(for weekKey: String) -> URL {
        layout.summaryDirectory(for: .week).appendingPathComponent("\(weekKey).intention.json")
    }
}
