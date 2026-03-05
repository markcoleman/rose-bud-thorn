import SwiftUI
import CoreModels
import ImageIO
#if os(iOS)
import UIKit
private typealias PolaroidPlatformImage = UIImage
#elseif os(macOS)
import AppKit
private typealias PolaroidPlatformImage = NSImage
#endif

public struct PolaroidCard: View {
    public let type: EntryType
    public let caption: String
    public let photoURL: URL?
    public let tiltAngle: Double
    public let reduceMotion: Bool

    @StateObject private var imageLoader = PolaroidImageLoader()
    @ScaledMetric(relativeTo: .body) private var baseCaptionSize: CGFloat = 21

    public init(
        type: EntryType,
        caption: String,
        photoURL: URL?,
        tiltAngle: Double = 0,
        reduceMotion: Bool
    ) {
        self.type = type
        self.caption = caption
        self.photoURL = photoURL
        self.tiltAngle = tiltAngle
        self.reduceMotion = reduceMotion
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerLabel

            photoRegion
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
                )

            captionRegion
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 10)
        .rotationEffect(.degrees(reduceMotion ? 0 : tiltAngle))
        .animation(reduceMotion ? nil : MotionTokens.quick, value: tiltAngle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .task(id: photoURL) {
            await imageLoader.load(url: photoURL, maxPixelSize: 1200)
        }
    }

    private var headerLabel: some View {
        HStack(spacing: 8) {
            Text(type.marker)
                .font(.title3)
            Text(type.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(polaroidInk)
            Spacer(minLength: 0)
        }
        .padding(.bottom, 12)
    }

    private var photoRegion: some View {
        ZStack {
            if let image = imageLoader.image {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(polaroidPhotoBackground)
                    .accessibilityHidden(true)
            } else if imageLoader.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(polaroidPhotoBackground)
            } else {
                placeholderPhoto
            }
        }
    }

    private var placeholderPhoto: some View {
        ZStack {
            LinearGradient(
                colors: [type.tint.opacity(0.16), DesignTokens.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                Image(systemName: AppIcon.mediaCount.systemName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(type.tint)
                Text("No photo yet")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private var captionRegion: some View {
        VStack(alignment: .leading, spacing: 6) {
                Text(captionText)
                    .font(captionFont)
                    .foregroundStyle(polaroidInk)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 14)

            if photoURL == nil {
                Text("Add a photo in Edit")
                    .font(.caption)
                    .foregroundStyle(polaroidSecondaryInk)
            }
        }
    }

    private var captionText: String {
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "No reflection captured."
        }
        return trimmed
    }

    private var captionFont: Font {
        if let platformScriptName = platformScriptFontName() {
            return .custom(platformScriptName, size: baseCaptionSize, relativeTo: .body)
        }
        return .system(.body, design: .rounded).weight(.medium)
    }

    private var accessibilityLabel: String {
        let hasPhotoText = photoURL == nil ? "No photo." : "Has photo."
        return "\(type.title). \(captionText). \(hasPhotoText)"
    }

    private var polaroidInk: Color {
        Color.black.opacity(0.80)
    }

    private var polaroidSecondaryInk: Color {
        Color.black.opacity(0.56)
    }

    private var polaroidPhotoBackground: Color {
        Color.black.opacity(0.06)
    }

    private func platformScriptFontName() -> String? {
        #if os(iOS)
        if UIFont(name: "Noteworthy-Bold", size: baseCaptionSize) != nil {
            return "Noteworthy-Bold"
        }
        if UIFont(name: "MarkerFelt-Wide", size: baseCaptionSize) != nil {
            return "MarkerFelt-Wide"
        }
        #elseif os(macOS)
        if NSFont(name: "Noteworthy-Bold", size: baseCaptionSize) != nil {
            return "Noteworthy-Bold"
        }
        if NSFont(name: "MarkerFelt-Wide", size: baseCaptionSize) != nil {
            return "MarkerFelt-Wide"
        }
        #endif
        return nil
    }
}

private final class PolaroidImageLoader: ObservableObject {
    @MainActor private static let cache = NSCache<NSString, PolaroidPlatformImage>()

    @MainActor @Published fileprivate var image: PolaroidPlatformImage?
    @MainActor @Published fileprivate var isLoading = false

    @MainActor
    fileprivate func load(url: URL?, maxPixelSize: CGFloat) async {
        guard let url else {
            image = nil
            isLoading = false
            return
        }

        let cacheKey = "\(url.path)-\(Int(maxPixelSize))" as NSString
        if let cached = Self.cache.object(forKey: cacheKey) {
            image = cached
            isLoading = false
            return
        }

        isLoading = true

        let result = await Task.detached(priority: .utility) {
            downsamplePolaroidImage(at: url, maxPixelSize: maxPixelSize)
        }.value

        isLoading = false
        image = result
        if let result {
            Self.cache.setObject(result, forKey: cacheKey)
        }
    }
}

private func downsamplePolaroidImage(at url: URL, maxPixelSize: CGFloat) -> PolaroidPlatformImage? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
        return nil
    }

    let options = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxPixelSize))
    ] as CFDictionary

    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
        return nil
    }

    #if os(iOS)
    return PolaroidPlatformImage(cgImage: cgImage)
    #elseif os(macOS)
    return PolaroidPlatformImage(cgImage: cgImage, size: .zero)
    #endif
}

private extension EntryType {
    var marker: String {
        switch self {
        case .rose:
            return "🌹"
        case .bud:
            return "🌱"
        case .thorn:
            return "🌵"
        }
    }

    var tint: Color {
        switch self {
        case .rose:
            return DesignTokens.rose
        case .bud:
            return DesignTokens.bud
        case .thorn:
            return DesignTokens.thorn
        }
    }
}

private extension Image {
    init(platformImage: PolaroidPlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #elseif os(macOS)
        self.init(nsImage: platformImage)
        #endif
    }
}
