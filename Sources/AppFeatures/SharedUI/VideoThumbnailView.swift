import SwiftUI

public struct VideoThumbnailView: View {
    public let url: URL
    public let size: CGFloat

    public init(url: URL, size: CGFloat = 52) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.75))

            VStack(spacing: 2) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Video")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Video attachment")
        .accessibilityHint(url.lastPathComponent)
    }
}
