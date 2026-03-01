import Foundation

public struct DocumentStoreConfiguration: Sendable {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public static func live(fileManager: FileManager = .default) throws -> DocumentStoreConfiguration {
        try legacyLive(fileManager: fileManager)
    }

    public static func legacyLive(fileManager: FileManager = .default) throws -> DocumentStoreConfiguration {
        if let ubiquityRoot = fileManager.url(forUbiquityContainerIdentifier: nil) {
            let documents = ubiquityRoot.appendingPathComponent("Documents", isDirectory: true)
            try fileManager.createDirectory(at: documents, withIntermediateDirectories: true)
            return DocumentStoreConfiguration(rootURL: documents)
        }

        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return DocumentStoreConfiguration(rootURL: documents)
    }

    public static func appGroup(
        appGroupID: String,
        fileManager: FileManager = .default
    ) throws -> DocumentStoreConfiguration {
        guard let groupRoot = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [
                NSDebugDescriptionErrorKey: "Could not resolve app group container for \(appGroupID)."
            ])
        }

        let documents = groupRoot.appendingPathComponent("Documents", isDirectory: true)
        try fileManager.createDirectory(at: documents, withIntermediateDirectories: true)
        return DocumentStoreConfiguration(rootURL: documents)
    }
}
