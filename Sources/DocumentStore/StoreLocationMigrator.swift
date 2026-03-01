import Foundation

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

        try fileManager.createDirectory(at: sharedRootURL, withIntermediateDirectories: true)

        for folderName in canonicalFolderNames {
            let legacyFolder = legacyRootURL.appendingPathComponent(folderName, isDirectory: true)
            let sharedFolder = sharedRootURL.appendingPathComponent(folderName, isDirectory: true)
            guard fileManager.fileExists(atPath: legacyFolder.path) else { continue }
            try mergeDirectoryIfNeeded(from: legacyFolder, to: sharedFolder, fileManager: fileManager)
        }

        defaults.set(true, forKey: migrationKey)
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

        let sourcePath = sourceDirectory.path
        let enumerator = fileManager.enumerator(
            at: sourceDirectory,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let sourceURL = enumerator?.nextObject() as? URL {
            let relativePath = sourceURL.path.replacingOccurrences(of: sourcePath + "/", with: "")
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

            if !fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }
        }
    }
}
