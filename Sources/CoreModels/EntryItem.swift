import Foundation

public struct EntryItem: Codable, Hashable, Sendable {
    public let type: EntryType
    public var shortText: String
    public var journalTextMarkdown: String
    public var photos: [PhotoRef]
    public var metadata: [String: String]
    public var updatedAt: Date

    public init(
        type: EntryType,
        shortText: String = "",
        journalTextMarkdown: String = "",
        photos: [PhotoRef] = [],
        metadata: [String: String] = [:],
        updatedAt: Date = .now
    ) {
        self.type = type
        self.shortText = shortText
        self.journalTextMarkdown = journalTextMarkdown
        self.photos = photos
        self.metadata = metadata
        self.updatedAt = updatedAt
    }

    public var combinedText: String {
        "\(shortText)\n\(journalTextMarkdown)"
    }

    public var hasPhotos: Bool {
        !photos.isEmpty
    }
}
