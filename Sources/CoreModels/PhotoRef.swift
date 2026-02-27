import Foundation

public struct PhotoRef: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let relativePath: String
    public let createdAt: Date
    public let pixelWidth: Int?
    public let pixelHeight: Int?

    public init(
        id: UUID,
        relativePath: String,
        createdAt: Date,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil
    ) {
        self.id = id
        self.relativePath = relativePath
        self.createdAt = createdAt
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}
