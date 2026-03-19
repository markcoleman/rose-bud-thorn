import Foundation

public enum WidgetSharedDefaults {
    public static let appGroupIdentifier = "group.com.rosebudthorn.ios.shared"
    public static let todaySnapshotKey = "widget.today.snapshot.v1"
    public static let privacyLockEnabledKey = "widget.privacy-lock-enabled.v1"
}

public struct WidgetTodaySnapshotPhoto: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let type: EntryType
    public let relativePath: String
    public let createdAt: Date
    public let thumbnailJPEGData: Data?

    public init(
        id: String,
        type: EntryType,
        relativePath: String,
        createdAt: Date,
        thumbnailJPEGData: Data? = nil
    ) {
        self.id = id
        self.type = type
        self.relativePath = relativePath
        self.createdAt = createdAt
        self.thumbnailJPEGData = thumbnailJPEGData
    }
}

public struct WidgetTodaySnapshot: Codable, Equatable, Sendable {
    public let dayKeyISODate: String
    public let roseExcerpt: String
    public let budExcerpt: String
    public let thornExcerpt: String
    public let photos: [WidgetTodaySnapshotPhoto]
    public let completionCount: Int
    public let updatedAt: Date

    public init(
        dayKeyISODate: String,
        roseExcerpt: String,
        budExcerpt: String,
        thornExcerpt: String,
        photos: [WidgetTodaySnapshotPhoto] = [],
        completionCount: Int,
        updatedAt: Date
    ) {
        self.dayKeyISODate = dayKeyISODate
        self.roseExcerpt = roseExcerpt
        self.budExcerpt = budExcerpt
        self.thornExcerpt = thornExcerpt
        self.photos = photos
        self.completionCount = min(max(completionCount, 0), EntryType.allCases.count)
        self.updatedAt = updatedAt
    }

    public var hasAnyContent: Bool {
        !roseExcerpt.isEmpty || !budExcerpt.isEmpty || !thornExcerpt.isEmpty || !photos.isEmpty
    }

    public func excerpt(for type: EntryType) -> String {
        switch type {
        case .rose:
            return roseExcerpt
        case .bud:
            return budExcerpt
        case .thorn:
            return thornExcerpt
        }
    }

    public func photo(at index: Int) -> WidgetTodaySnapshotPhoto? {
        guard photos.indices.contains(index) else { return nil }
        return photos[index]
    }
}

public enum WidgetTodayDisplayState: Equatable, Sendable {
    case privacyLocked
    case notStarted
    case inProgress
    case complete
}

public struct WidgetTodayDisplayContent: Equatable, Sendable {
    public let state: WidgetTodayDisplayState
    public let completionCount: Int
    public let photoCount: Int
    public let roseExcerpt: String
    public let budExcerpt: String
    public let thornExcerpt: String

    public init(snapshot: WidgetTodaySnapshot?, isPrivacyLockEnabled: Bool) {
        if isPrivacyLockEnabled {
            self.state = .privacyLocked
            self.completionCount = 0
            self.photoCount = 0
            self.roseExcerpt = ""
            self.budExcerpt = ""
            self.thornExcerpt = ""
            return
        }

        guard let snapshot else {
            self.state = .notStarted
            self.completionCount = 0
            self.photoCount = 0
            self.roseExcerpt = ""
            self.budExcerpt = ""
            self.thornExcerpt = ""
            return
        }

        self.completionCount = min(max(snapshot.completionCount, 0), EntryType.allCases.count)
        self.photoCount = snapshot.photos.count
        self.roseExcerpt = snapshot.roseExcerpt
        self.budExcerpt = snapshot.budExcerpt
        self.thornExcerpt = snapshot.thornExcerpt

        if self.completionCount >= EntryType.allCases.count {
            self.state = .complete
        } else if snapshot.hasAnyContent {
            self.state = .inProgress
        } else {
            self.state = .notStarted
        }
    }

    public var hasAnyContent: Bool {
        !roseExcerpt.isEmpty || !budExcerpt.isEmpty || !thornExcerpt.isEmpty || photoCount > 0
    }

    public func excerpt(for type: EntryType) -> String {
        switch type {
        case .rose:
            return roseExcerpt
        case .bud:
            return budExcerpt
        case .thorn:
            return thornExcerpt
        }
    }
}

public extension EntryDay {
    func widgetTodaySnapshot(now: Date = .now, excerptLimit: Int = 72) -> WidgetTodaySnapshot {
        WidgetTodaySnapshot(
            dayKeyISODate: dayKey.isoDate,
            roseExcerpt: roseItem.widgetExcerpt(limit: excerptLimit),
            budExcerpt: budItem.widgetExcerpt(limit: excerptLimit),
            thornExcerpt: thornItem.widgetExcerpt(limit: excerptLimit),
            photos: widgetPhotos,
            completionCount: completionCount,
            updatedAt: max(updatedAt, now)
        )
    }

    private var widgetPhotos: [WidgetTodaySnapshotPhoto] {
        let rosePhotos = roseItem.photos.map { ref in
            WidgetTodaySnapshotPhoto(
                id: ref.id.uuidString,
                type: .rose,
                relativePath: ref.relativePath,
                createdAt: ref.createdAt
            )
        }
        let budPhotos = budItem.photos.map { ref in
            WidgetTodaySnapshotPhoto(
                id: ref.id.uuidString,
                type: .bud,
                relativePath: ref.relativePath,
                createdAt: ref.createdAt
            )
        }
        let thornPhotos = thornItem.photos.map { ref in
            WidgetTodaySnapshotPhoto(
                id: ref.id.uuidString,
                type: .thorn,
                relativePath: ref.relativePath,
                createdAt: ref.createdAt
            )
        }

        return (rosePhotos + budPhotos + thornPhotos).sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id > rhs.id
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
}

private extension EntryItem {
    func widgetExcerpt(limit: Int) -> String {
        let short = shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !short.isEmpty {
            return short.normalizedWidgetExcerpt(limit: limit)
        }

        let journal = journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if !journal.isEmpty {
            return journal.normalizedWidgetExcerpt(limit: limit)
        }

        if hasMedia {
            return "Media added"
        }

        return ""
    }
}

private extension String {
    func normalizedWidgetExcerpt(limit: Int) -> String {
        let normalized = replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        guard normalized.count > limit, limit > 1 else {
            return normalized
        }

        return String(normalized.prefix(limit - 1)) + "…"
    }
}
