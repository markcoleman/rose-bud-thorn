import SwiftUI
import CoreModels

public struct PhotoThumbnailView: View {
    public let url: URL
    public let size: CGFloat

    public init(url: URL, size: CGFloat = 52) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: size, height: size)
                    .background(Color.secondary.opacity(0.1))
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .failure:
                Image(systemName: "photo.badge.exclamationmark")
                    .frame(width: size, height: size)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            @unknown default:
                EmptyView()
            }
        }
    }
}
