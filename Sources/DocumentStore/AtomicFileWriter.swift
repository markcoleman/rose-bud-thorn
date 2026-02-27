import Foundation

public struct AtomicFileWriter: Sendable {
    public init() {}

    public func write(data: Data, to destinationURL: URL, fileManager: FileManager = .default) throws {
        let destinationDirectory = destinationURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)

        let tempURL = destinationDirectory.appendingPathComponent(".tmp-\(UUID().uuidString)")
        try data.write(to: tempURL, options: .atomic)

        if fileManager.fileExists(atPath: destinationURL.path) {
            _ = try fileManager.replaceItemAt(destinationURL, withItemAt: tempURL)
        } else {
            try fileManager.moveItem(at: tempURL, to: destinationURL)
        }
    }
}
