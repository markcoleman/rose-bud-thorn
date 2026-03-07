import Foundation
import CoreModels

public enum JournalSaveFeedbackState: Sendable, Equatable {
    case draft
    case saving
    case saved(Date)
    case complete(Date?)
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
        self.hasMedia = entry.roseItem.hasMedia || entry.budItem.hasMedia || entry.thornItem.hasMedia
        self.updatedAt = entry.updatedAt
    }

    public var completionCount: Int {
        [roseText, budText, thornText]
            .map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .filter { $0 }
            .count
    }

    public func lines() -> [Line] {
        let allLines: [Line] = [
            Line(type: .rose, text: roseText),
            Line(type: .bud, text: budText),
            Line(type: .thorn, text: thornText)
        ]

        return allLines.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
