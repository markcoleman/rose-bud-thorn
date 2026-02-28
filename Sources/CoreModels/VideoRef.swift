import Foundation

public struct VideoRef: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let relativePath: String
    public let createdAt: Date
    public let durationSeconds: Double
    public let pixelWidth: Int?
    public let pixelHeight: Int?
    public let hasAudio: Bool

    public init(
        id: UUID,
        relativePath: String,
        createdAt: Date,
        durationSeconds: Double,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil,
        hasAudio: Bool
    ) {
        self.id = id
        self.relativePath = relativePath
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.hasAudio = hasAudio
    }
}
