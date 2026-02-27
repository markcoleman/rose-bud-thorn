import Foundation

public struct FileCoordinatorAdapter: Sendable {
    public init() {}

    public func coordinateRead<T>(at url: URL, _ block: (URL) throws -> T) throws -> T {
        try block(url)
    }

    public func coordinateWrite<T>(at url: URL, _ block: (URL) throws -> T) throws -> T {
        try block(url)
    }
}
