import Foundation
import CoreModels

public struct FileLayout: Sendable {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public var entriesRoot: URL {
        rootURL.appendingPathComponent("Entries", isDirectory: true)
    }

    public var summariesRoot: URL {
        rootURL.appendingPathComponent("Summaries", isDirectory: true)
    }

    public var indexRoot: URL {
        rootURL.appendingPathComponent("Index", isDirectory: true)
    }

    public var conflictsRoot: URL {
        rootURL.appendingPathComponent("Conflicts", isDirectory: true)
    }

    public var exportsRoot: URL {
        rootURL.appendingPathComponent("Exports", isDirectory: true)
    }

    public func dayDirectory(for day: LocalDayKey) -> URL {
        entriesRoot
            .appendingPathComponent(day.year, isDirectory: true)
            .appendingPathComponent(day.month, isDirectory: true)
            .appendingPathComponent(day.day, isDirectory: true)
    }

    public func entryFileURL(for day: LocalDayKey) -> URL {
        dayDirectory(for: day).appendingPathComponent("entry.json")
    }

    public func itemDirectory(for day: LocalDayKey, type: EntryType) -> URL {
        dayDirectory(for: day).appendingPathComponent(type.folderName, isDirectory: true)
    }

    public func attachmentDirectory(for day: LocalDayKey, type: EntryType) -> URL {
        itemDirectory(for: day, type: type).appendingPathComponent("attachments", isDirectory: true)
    }

    public func summaryDirectory(for period: SummaryPeriod) -> URL {
        summariesRoot.appendingPathComponent(period.storageFolder, isDirectory: true)
    }

    public func summaryMarkdownURL(period: SummaryPeriod, key: String) -> URL {
        summaryDirectory(for: period).appendingPathComponent("\(key).md")
    }

    public func summaryMetadataURL(period: SummaryPeriod, key: String) -> URL {
        summaryDirectory(for: period).appendingPathComponent("\(key).json")
    }

    public var indexFileURL: URL {
        indexRoot.appendingPathComponent("index.json")
    }

    public func ensureBaseDirectories(using fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: entriesRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: summariesRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: indexRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: conflictsRoot, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: exportsRoot, withIntermediateDirectories: true)
    }
}
