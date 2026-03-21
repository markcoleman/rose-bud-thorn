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
