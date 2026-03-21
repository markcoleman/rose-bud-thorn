import Foundation
import CoreModels

public enum StoreLocationMigrator {
    public static func migrateLegacyStoreIfNeeded(
        from legacyRootURL: URL,
        to sharedRootURL: URL,
        defaults: UserDefaults = .standard,
        migrationKey: String = "document-store.app-group-migration.v1",
        fileManager: FileManager = .default
    ) throws {
        if defaults.bool(forKey: migrationKey) {
            return
        }

        if legacyRootURL.standardizedFileURL == sharedRootURL.standardizedFileURL {
            defaults.set(true, forKey: migrationKey)
            return
        }

        try mergeStoreContents(
            from: legacyRootURL,
            to: sharedRootURL,
            fileManager: fileManager
        )

        defaults.set(true, forKey: migrationKey)
    }

    public static func mergeStoreContents(
        from sourceRootURL: URL,
        to destinationRootURL: URL,
        fileManager: FileManager = .default
    ) throws {
        if sourceRootURL.standardizedFileURL == destinationRootURL.standardizedFileURL {
            return
        }

        try fileManager.createDirectory(at: destinationRootURL, withIntermediateDirectories: true)

        for folderName in canonicalFolderNames {
            let sourceFolder = sourceRootURL.appendingPathComponent(folderName, isDirectory: true)
            let destinationFolder = destinationRootURL.appendingPathComponent(folderName, isDirectory: true)
            guard fileManager.fileExists(atPath: sourceFolder.path) else { continue }
            try mergeDirectoryIfNeeded(from: sourceFolder, to: destinationFolder, fileManager: fileManager)
        }
    }

    public static func hasCanonicalData(
        at rootURL: URL,
        fileManager: FileManager = .default
    ) -> Bool {
        for folderName in canonicalFolderNames {
            let folder = rootURL.appendingPathComponent(folderName, isDirectory: true)
            guard fileManager.fileExists(atPath: folder.path) else { continue }

            let enumerator = fileManager.enumerator(
                at: folder,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )

            while let candidateURL = enumerator?.nextObject() as? URL {
                let values = try? candidateURL.resourceValues(forKeys: [.isRegularFileKey])
                if values?.isRegularFile == true {
                    return true
                }
            }
        }

        return false
    }

    private static let canonicalFolderNames = [
        "Entries",
        "Summaries",
        "Index",
        "Conflicts",
        "Exports"
    ]

    private static func mergeDirectoryIfNeeded(
        from sourceDirectory: URL,
        to destinationDirectory: URL,
        fileManager: FileManager
    ) throws {
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            try fileManager.copyItem(at: sourceDirectory, to: destinationDirectory)
            return
        }

        let resolvedSourceDirectory = sourceDirectory.resolvingSymlinksInPath()
        let sourceDirectoryComponents = resolvedSourceDirectory.pathComponents
        let enumerator = fileManager.enumerator(
            at: sourceDirectory,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let sourceURL = enumerator?.nextObject() as? URL {
            let resolvedSourceURL = sourceURL.resolvingSymlinksInPath()
            let sourceComponents = resolvedSourceURL.pathComponents
            guard sourceComponents.count > sourceDirectoryComponents.count else {
                continue
            }

            let relativePath = sourceComponents
                .dropFirst(sourceDirectoryComponents.count)
                .joined(separator: "/")
            let destinationURL = destinationDirectory.appendingPathComponent(relativePath)

            let values = try sourceURL.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            if values.isDirectory == true {
                if !fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
                }
                continue
            }

            guard values.isRegularFile == true else {
                continue
            }

            let parent = destinationURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: parent.path) {
                try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
            }

            if sourceDirectory.lastPathComponent == "Entries",
               sourceURL.lastPathComponent == "entry.json",
               fileManager.fileExists(atPath: destinationURL.path) {
                mergeEntryFileIfPossible(from: sourceURL, to: destinationURL)
                continue
            }

            if !fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }
        }
    }

    private static func mergeEntryFileIfPossible(from sourceURL: URL, to destinationURL: URL) {
        do {
            try mergeEntryFile(from: sourceURL, to: destinationURL)
        } catch {
            // Preserve destination content if either side can't be parsed as EntryDay.
        }
    }

    private static func mergeEntryFile(from sourceURL: URL, to destinationURL: URL) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let sourceData = try Data(contentsOf: sourceURL)
        let destinationData = try Data(contentsOf: destinationURL)
        let sourceEntry = try decoder.decode(EntryDay.self, from: sourceData)
        let destinationEntry = try decoder.decode(EntryDay.self, from: destinationData)

        let merged = mergeEntry(existing: destinationEntry, incoming: sourceEntry)
        let mergedData = try encoder.encode(merged)
        try mergedData.write(to: destinationURL, options: .atomic)
    }

    private static func mergeEntry(existing: EntryDay, incoming: EntryDay) -> EntryDay {
        var merged = incoming
        merged.roseItem = mergeItem(existing.roseItem, incoming.roseItem)
        merged.budItem = mergeItem(existing.budItem, incoming.budItem)
        merged.thornItem = mergeItem(existing.thornItem, incoming.thornItem)
        merged.tags = Array(Set(existing.tags).union(incoming.tags)).sorted()
        if merged.mood == nil {
            merged.mood = existing.mood
        }
        merged.updatedAt = max(existing.updatedAt, incoming.updatedAt)

        return EntryDay(
            schemaVersion: max(existing.schemaVersion, incoming.schemaVersion),
            dayKey: merged.dayKey,
            roseItem: merged.roseItem,
            budItem: merged.budItem,
            thornItem: merged.thornItem,
            tags: merged.tags,
            mood: merged.mood,
            createdAt: min(existing.createdAt, incoming.createdAt),
            updatedAt: merged.updatedAt
        )
    }

    private static func mergeItem(_ existing: EntryItem, _ incoming: EntryItem) -> EntryItem {
        let latest = existing.updatedAt >= incoming.updatedAt ? existing : incoming
        return EntryItem(
            type: latest.type,
            shortText: latest.shortText,
            journalTextMarkdown: latest.journalTextMarkdown,
            photos: mergeUnique(existing.photos, incoming.photos),
            videos: mergeUnique(existing.videos, incoming.videos),
            metadata: latest.metadata,
            updatedAt: max(existing.updatedAt, incoming.updatedAt)
        )
    }

    private static func mergeUnique<Element: Identifiable>(_ lhs: [Element], _ rhs: [Element]) -> [Element]
    where Element.ID: Hashable {
        var seen: Set<Element.ID> = []
        var merged: [Element] = []

        for item in lhs {
            if seen.insert(item.id).inserted {
                merged.append(item)
            }
        }

        for item in rhs {
            if seen.insert(item.id).inserted {
                merged.append(item)
            }
        }

        return merged
    }
}
