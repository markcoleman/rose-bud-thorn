import Foundation

public struct EntryDay: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 2

    public let schemaVersion: Int
    public let dayKey: LocalDayKey
    public var roseItem: EntryItem
    public var budItem: EntryItem
    public var thornItem: EntryItem
    public var tags: [String]
    public var mood: Int?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        schemaVersion: Int = EntryDay.currentSchemaVersion,
        dayKey: LocalDayKey,
        roseItem: EntryItem,
        budItem: EntryItem,
        thornItem: EntryItem,
        tags: [String] = [],
        mood: Int? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.schemaVersion = schemaVersion
        self.dayKey = dayKey
        self.roseItem = roseItem
        self.budItem = budItem
        self.thornItem = thornItem
        self.tags = tags
        self.mood = mood
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public static func empty(dayKey: LocalDayKey, now: Date = .now) -> EntryDay {
        EntryDay(
            dayKey: dayKey,
            roseItem: EntryItem(type: .rose, updatedAt: now),
            budItem: EntryItem(type: .bud, updatedAt: now),
            thornItem: EntryItem(type: .thorn, updatedAt: now),
            createdAt: now,
            updatedAt: now
        )
    }

    public func item(for type: EntryType) -> EntryItem {
        switch type {
        case .rose: return roseItem
        case .bud: return budItem
        case .thorn: return thornItem
        }
    }

    public mutating func setItem(_ item: EntryItem, for type: EntryType) {
        switch type {
        case .rose: roseItem = item
        case .bud: budItem = item
        case .thorn: thornItem = item
        }
        updatedAt = max(updatedAt, item.updatedAt)
    }

    public var hasAnyPhotos: Bool {
        roseItem.hasMedia || budItem.hasMedia || thornItem.hasMedia
    }
}

extension EntryDay {
    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case dayKey
        case roseItem
        case budItem
        case thornItem
        case tags
        case mood
        case favorite
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        dayKey = try container.decode(LocalDayKey.self, forKey: .dayKey)
        roseItem = try container.decode(EntryItem.self, forKey: .roseItem)
        budItem = try container.decode(EntryItem.self, forKey: .budItem)
        thornItem = try container.decode(EntryItem.self, forKey: .thornItem)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        mood = try container.decodeIfPresent(Int.self, forKey: .mood)
        _ = try container.decodeIfPresent(Bool.self, forKey: .favorite)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(dayKey, forKey: .dayKey)
        try container.encode(roseItem, forKey: .roseItem)
        try container.encode(budItem, forKey: .budItem)
        try container.encode(thornItem, forKey: .thornItem)
        try container.encode(tags, forKey: .tags)
        try container.encodeIfPresent(mood, forKey: .mood)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
