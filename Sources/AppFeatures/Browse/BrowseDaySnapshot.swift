import Foundation
import CoreModels

public struct BrowseDaySnapshot: Hashable, Sendable, Identifiable {
    public let dayKey: LocalDayKey
    public let rosePreview: String
    public let budPreview: String
    public let thornPreview: String
    public let mood: Int?
    public let favorite: Bool
    public let hasMedia: Bool
    public let tags: [String]
    public let updatedAt: Date
    public let mediaCount: Int

    public var id: LocalDayKey { dayKey }

    public init(
        dayKey: LocalDayKey,
        rosePreview: String,
        budPreview: String,
        thornPreview: String,
        mood: Int?,
        favorite: Bool,
        hasMedia: Bool,
        tags: [String],
        updatedAt: Date,
        mediaCount: Int
    ) {
        self.dayKey = dayKey
        self.rosePreview = rosePreview
        self.budPreview = budPreview
        self.thornPreview = thornPreview
        self.mood = mood
        self.favorite = favorite
        self.hasMedia = hasMedia
        self.tags = tags
        self.updatedAt = updatedAt
        self.mediaCount = mediaCount
    }
}

public extension BrowseDaySnapshot {
    init(entry: EntryDay) {
        let rosePreview = Self.previewText(from: entry.roseItem)
        let budPreview = Self.previewText(from: entry.budItem)
        let thornPreview = Self.previewText(from: entry.thornItem)
        let mediaCount = entry.roseItem.photos.count + entry.roseItem.videos.count +
            entry.budItem.photos.count + entry.budItem.videos.count +
            entry.thornItem.photos.count + entry.thornItem.videos.count

        self.init(
            dayKey: entry.dayKey,
            rosePreview: rosePreview,
            budPreview: budPreview,
            thornPreview: thornPreview,
            mood: entry.mood,
            favorite: entry.favorite,
            hasMedia: mediaCount > 0,
            tags: entry.tags,
            updatedAt: entry.updatedAt,
            mediaCount: mediaCount
        )
    }

    var hasRoseContent: Bool { !rosePreview.isEmpty }
    var hasBudContent: Bool { !budPreview.isEmpty }
    var hasThornContent: Bool { !thornPreview.isEmpty }
    var completionCount: Int {
        [hasRoseContent, hasBudContent, hasThornContent].filter { $0 }.count
    }
}

public enum BrowseQuickFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case favorites
    case media
    case thisMonth
    case onThisDay

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "All"
        case .favorites: return "Favorites"
        case .media: return "Has Media"
        case .thisMonth: return "This Month"
        case .onThisDay: return "On This Day"
        }
    }

    public var systemImage: String {
        switch self {
        case .all: return "tray.full"
        case .favorites: return "star.fill"
        case .media: return "photo.on.rectangle.angled"
        case .thisMonth: return "calendar.badge.clock"
        case .onThisDay: return "clock.arrow.circlepath"
        }
    }
}

public struct BrowseMonthSection: Hashable, Sendable, Identifiable {
    public let monthKey: String
    public let title: String
    public let days: [BrowseDaySnapshot]

    public var id: String { monthKey }

    public init(monthKey: String, title: String, days: [BrowseDaySnapshot]) {
        self.monthKey = monthKey
        self.title = title
        self.days = days
    }
}

private extension BrowseDaySnapshot {
    static func previewText(from item: EntryItem) -> String {
        let short = item.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !short.isEmpty {
            return String(short.prefix(100))
        }

        let journal = item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return String(journal.prefix(100))
        }

        return ""
    }
}
