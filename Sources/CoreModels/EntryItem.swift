import Foundation

public struct EntryItem: Codable, Hashable, Sendable {
    public let type: EntryType
    public var shortText: String
    public var journalTextMarkdown: String
    public var photos: [PhotoRef]
    public var videos: [VideoRef]
    public var metadata: [String: String]
    public var updatedAt: Date

    public init(
        type: EntryType,
        shortText: String = "",
        journalTextMarkdown: String = "",
        photos: [PhotoRef] = [],
        videos: [VideoRef] = [],
        metadata: [String: String] = [:],
        updatedAt: Date = .now
    ) {
        self.type = type
        self.shortText = shortText
        self.journalTextMarkdown = journalTextMarkdown
        self.photos = photos
        self.videos = videos
        self.metadata = metadata
        self.updatedAt = updatedAt
    }

    public var combinedText: String {
        "\(shortText)\n\(journalTextMarkdown)"
    }

    public var hasPhotos: Bool {
        !photos.isEmpty
    }

    public var hasMedia: Bool {
        !photos.isEmpty || !videos.isEmpty
    }
}

extension EntryItem {
    private enum CodingKeys: String, CodingKey {
        case type
        case shortText
        case journalTextMarkdown
        case photos
        case videos
        case metadata
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(EntryType.self, forKey: .type)
        shortText = try container.decode(String.self, forKey: .shortText)
        journalTextMarkdown = try container.decode(String.self, forKey: .journalTextMarkdown)
        photos = try container.decodeIfPresent([PhotoRef].self, forKey: .photos) ?? []
        videos = try container.decodeIfPresent([VideoRef].self, forKey: .videos) ?? []
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(shortText, forKey: .shortText)
        try container.encode(journalTextMarkdown, forKey: .journalTextMarkdown)
        try container.encode(photos, forKey: .photos)
        try container.encode(videos, forKey: .videos)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
