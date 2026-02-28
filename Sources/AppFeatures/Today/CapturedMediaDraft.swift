import Foundation

public enum CapturedMediaDraft: Equatable, Sendable {
    case photo(url: URL, pixelWidth: Int?, pixelHeight: Int?)
    case video(url: URL, durationSeconds: Double, pixelWidth: Int?, pixelHeight: Int?, hasAudio: Bool)

    public var url: URL {
        switch self {
        case .photo(let url, _, _):
            return url
        case .video(let url, _, _, _, _):
            return url
        }
    }
}
