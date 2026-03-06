import Foundation
import CoreModels

public enum JournalSaveFeedbackState: Sendable, Equatable {
    case draft
    case saving
    case saved(Date)
    case complete(Date?)
}

public enum JournalMode: Sendable, Equatable {
    case timeline
    case search
}

public enum JournalCategoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case rose
    case bud
    case thorn

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "All"
        case .rose: return "Rose"
        case .bud: return "Bud"
        case .thorn: return "Thorn"
        }
    }

    var entryTypes: Set<EntryType> {
        switch self {
        case .all:
            return Set(EntryType.allCases)
        case .rose:
            return [.rose]
        case .bud:
            return [.bud]
        case .thorn:
            return [.thorn]
        }
    }
}

public struct JournalFilters: Sendable, Equatable {
    public var category: JournalCategoryFilter
    public var hasPhotoOnly: Bool
    public var favoritesOnly: Bool

    public init(
        category: JournalCategoryFilter = .all,
        hasPhotoOnly: Bool = false,
        favoritesOnly: Bool = false
    ) {
        self.category = category
        self.hasPhotoOnly = hasPhotoOnly
        self.favoritesOnly = favoritesOnly
    }
}

public struct EntryDaySummary: Sendable, Hashable, Identifiable {
    public struct Line: Sendable, Hashable, Identifiable {
        public let type: EntryType
        public let text: String

        public var id: String {
            "\(type.rawValue):\(text)"
        }
    }

    public let dayKey: LocalDayKey
    public let roseText: String
    public let budText: String
    public let thornText: String
    public let roseHasMedia: Bool
    public let budHasMedia: Bool
    public let thornHasMedia: Bool
    public let previewPhotoRefs: [PhotoRef]
    public let favorite: Bool
    public let hasMedia: Bool
    public let updatedAt: Date

    public var id: LocalDayKey { dayKey }

    public init(entry: EntryDay) {
        self.dayKey = entry.dayKey
        self.roseText = Self.previewText(from: entry.roseItem)
        self.budText = Self.previewText(from: entry.budItem)
        self.thornText = Self.previewText(from: entry.thornItem)
        self.roseHasMedia = entry.roseItem.hasMedia
        self.budHasMedia = entry.budItem.hasMedia
        self.thornHasMedia = entry.thornItem.hasMedia
        let allPhotos = entry.roseItem.photos + entry.budItem.photos + entry.thornItem.photos
        self.previewPhotoRefs = Self.latestPhotoRefs(in: allPhotos, limit: 3)
        self.favorite = entry.favorite
        self.hasMedia = entry.roseItem.hasMedia || entry.budItem.hasMedia || entry.thornItem.hasMedia
        self.updatedAt = entry.updatedAt
    }

    public var completionCount: Int {
        [roseText, budText, thornText]
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .filter { $0 }
            .count
    }

    public func lines(for category: JournalCategoryFilter) -> [Line] {
        let allLines: [Line] = [
            Line(type: .rose, text: roseText),
            Line(type: .bud, text: budText),
            Line(type: .thorn, text: thornText)
        ]

        let visible = allLines.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        switch category {
        case .all:
            return visible
        case .rose:
            return visible.filter { $0.type == .rose }
        case .bud:
            return visible.filter { $0.type == .bud }
        case .thorn:
            return visible.filter { $0.type == .thorn }
        }
    }

    public func matchingLines(query: String, category: JournalCategoryFilter) -> [Line] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return lines(for: category)
        }

        return lines(for: category).filter { line in
            line.text.lowercased().contains(normalized)
        }
    }

    private static func previewText(from item: EntryItem) -> String {
        let short = item.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !short.isEmpty {
            return String(short.prefix(120))
        }

        let journal = item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return String(journal.prefix(120))
        }

        return ""
    }

    private static func latestPhotoRefs(in photos: [PhotoRef], limit: Int) -> [PhotoRef] {
        guard limit > 0 else { return [] }

        return photos
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id.uuidString > rhs.id.uuidString
                }
                return lhs.createdAt > rhs.createdAt
            }
            .prefix(limit)
            .map { $0 }
    }
}
