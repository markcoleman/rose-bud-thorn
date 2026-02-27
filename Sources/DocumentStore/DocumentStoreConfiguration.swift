import Foundation

public struct DocumentStoreConfiguration: Sendable {
    public let rootURL: URL

    public init(rootURL: URL) {
        self.rootURL = rootURL
    }

    public static func live(fileManager: FileManager = .default) throws -> DocumentStoreConfiguration {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return DocumentStoreConfiguration(rootURL: documents)
    }
}
