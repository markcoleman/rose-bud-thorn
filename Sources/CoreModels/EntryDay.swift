import Foundation

public struct EntryDay: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let dayKey: LocalDayKey
    public var roseItem: EntryItem
    public var budItem: EntryItem
    public var thornItem: EntryItem
    public var tags: [String]
    public var mood: Int?
    public var favorite: Bool
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
        favorite: Bool = false,
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
        self.favorite = favorite
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
