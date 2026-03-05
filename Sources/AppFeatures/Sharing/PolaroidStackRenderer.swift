import Foundation
import SwiftUI
import CoreModels
import ImageIO

#if os(iOS)
import UIKit
private typealias PolaroidRenderPlatformImage = UIImage
#elseif os(macOS)
import AppKit
private typealias PolaroidRenderPlatformImage = NSImage
#endif

public struct PolaroidStackRenderConfiguration: Sendable, Equatable {
    public var canvasWidth: Int
    public var maxCaptionLength: Int
    public var includeWatermark: Bool

    public init(
        canvasWidth: Int = 1080,
        maxCaptionLength: Int = 160,
        includeWatermark: Bool = true
    ) {
        self.canvasWidth = canvasWidth
        self.maxCaptionLength = maxCaptionLength
        self.includeWatermark = includeWatermark
    }

    public static let `default` = PolaroidStackRenderConfiguration()
}

public struct PolaroidStackRenderMetadata: Sendable, Equatable {
    public let canvasWidth: Int
    public let canvasHeight: Int
    public let orderedTypes: [EntryType]
    public let truncatedCaptions: [EntryType: String]
    public let maxCaptionLength: Int

    public init(
        canvasWidth: Int,
        canvasHeight: Int,
        orderedTypes: [EntryType],
        truncatedCaptions: [EntryType: String],
        maxCaptionLength: Int
    ) {
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.orderedTypes = orderedTypes
        self.truncatedCaptions = truncatedCaptions
        self.maxCaptionLength = maxCaptionLength
    }
}

public struct PolaroidStackRenderOutput: Sendable {
    public let pngData: Data
    public let metadata: PolaroidStackRenderMetadata

    public init(pngData: Data, metadata: PolaroidStackRenderMetadata) {
        self.pngData = pngData
        self.metadata = metadata
    }
}

public enum PolaroidStackRendererError: LocalizedError, Sendable {
    case renderFailed

    public var errorDescription: String? {
        "Unable to generate the Polaroid stack image."
    }
}

public struct PolaroidStackRenderer {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func render(
        dayTitle: String,
        selections: [DayShareCardSelection],
        configuration: PolaroidStackRenderConfiguration = .default
    ) async throws -> PolaroidStackRenderOutput {
        let safeWidth = max(720, configuration.canvasWidth)
        let layout = PolaroidStackRenderLayout(canvasWidth: safeWidth, includeWatermark: configuration.includeWatermark)

        let orderedCards = EntryType.allCases.map { type in
            makeCard(
                for: type,
                in: selections,
                maxCaptionLength: configuration.maxCaptionLength
            )
        }

        let truncatedCaptions = Dictionary(uniqueKeysWithValues: orderedCards.map { ($0.type, $0.caption) })
        let metadata = PolaroidStackRenderMetadata(
            canvasWidth: safeWidth,
            canvasHeight: Int(layout.canvasHeight.rounded()),
            orderedTypes: orderedCards.map(\.type),
            truncatedCaptions: truncatedCaptions,
            maxCaptionLength: configuration.maxCaptionLength
        )

        let pngData = try await renderPNG(
            dayTitle: dayTitle,
            cards: orderedCards,
            layout: layout
        )

        return PolaroidStackRenderOutput(pngData: pngData, metadata: metadata)
    }

    private func makeCard(
        for type: EntryType,
        in selections: [DayShareCardSelection],
        maxCaptionLength: Int
    ) -> PolaroidStackRenderCard {
        let matched = selections.first(where: { $0.type == type })
        let caption = normalizedCaption(from: matched?.textPreview ?? "", maxLength: maxCaptionLength)

        let sourceURL: URL?
        if let existing = matched?.sourceURL, fileManager.fileExists(atPath: existing.path) {
            sourceURL = existing
        } else {
            sourceURL = nil
        }

        return PolaroidStackRenderCard(type: type, caption: caption, sourceURL: sourceURL)
    }

    private func normalizedCaption(from raw: String, maxLength: Int) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "No reflection captured."
        }

        if trimmed.count <= maxLength {
            return trimmed
        }
        let prefix = trimmed.prefix(maxLength).trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(prefix)…"
    }

    private func renderPNG(
        dayTitle: String,
        cards: [PolaroidStackRenderCard],
        layout: PolaroidStackRenderLayout
    ) async throws -> Data {
        guard let pngData = await MainActor.run(body: { () -> Data? in
            let view = PolaroidStackShareView(dayTitle: dayTitle, cards: cards, layout: layout)
                .frame(width: layout.canvasWidth, height: layout.canvasHeight)

            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = ProposedViewSize(width: layout.canvasWidth, height: layout.canvasHeight)

            #if os(iOS)
            return renderer.uiImage?.pngData()
            #elseif os(macOS)
            guard let image = renderer.nsImage,
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData) else {
                return nil
            }
            return bitmap.representation(using: .png, properties: [:])
            #else
            return nil
            #endif
        }) else {
            throw PolaroidStackRendererError.renderFailed
        }

        return pngData
    }
}

private struct PolaroidStackRenderCard: Sendable {
    let type: EntryType
    let caption: String
    let sourceURL: URL?
}

private struct PolaroidStackRenderLayout: Sendable {
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat
    let outerPadding: CGFloat
    let cardSpacing: CGFloat
    let cardWidth: CGFloat
    let cardPhotoSize: CGFloat
    let cardCaptionHeight: CGFloat
    let includeWatermark: Bool

    init(canvasWidth: Int, includeWatermark: Bool) {
        self.canvasWidth = CGFloat(canvasWidth)
        self.outerPadding = 52
        self.cardSpacing = 26
        self.cardWidth = CGFloat(canvasWidth) - (outerPadding * 2)
        self.cardPhotoSize = cardWidth - 52
        self.cardCaptionHeight = 120
        self.includeWatermark = includeWatermark

        let headerHeight: CGFloat = 150
        let footerHeight: CGFloat = includeWatermark ? 52 : 20
        let cardHeight = cardPhotoSize + cardCaptionHeight + 68
        self.canvasHeight = headerHeight + footerHeight + (cardHeight * 3) + (cardSpacing * 2) + (outerPadding * 2)
    }
}

private struct PolaroidStackShareView: View {
    let dayTitle: String
    let cards: [PolaroidStackRenderCard]
    let layout: PolaroidStackRenderLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Rose • Bud • Thorn")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                Text(dayTitle)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
            }

            VStack(spacing: layout.cardSpacing) {
                ForEach(cards, id: \.type) { card in
                    PolaroidStackShareCardView(card: card, layout: layout)
                }
            }

            if layout.includeWatermark {
                Text("Rose, Bud, Thorn")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
        }
        .padding(layout.outerPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [DesignTokens.surface, DesignTokens.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct PolaroidStackShareCardView: View {
    let card: PolaroidStackRenderCard
    let layout: PolaroidStackRenderLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(card.type.marker)
                    .font(.system(size: 34))
                Text(card.type.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Spacer(minLength: 0)
            }

            ZStack {
                if let sourceURL = card.sourceURL,
                   let image = loadPolaroidRenderImage(at: sourceURL, maxPixelSize: layout.cardPhotoSize * 2) {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: layout.cardPhotoSize, height: layout.cardPhotoSize)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(card.type.tint.opacity(0.16))
                    VStack(spacing: 6) {
                        Image(systemName: AppIcon.mediaCount.systemName)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(card.type.tint)
                        Text("No photo")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    }
                }
            }
            .frame(width: layout.cardPhotoSize, height: layout.cardPhotoSize)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(card.caption)
                .font(.system(size: 29, weight: .medium, design: .rounded))
                .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(width: layout.cardWidth, alignment: .leading)
        .background(Color.white.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 7)
    }
}

private func loadPolaroidRenderImage(at url: URL, maxPixelSize: CGFloat) -> PolaroidRenderPlatformImage? {
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
    return PolaroidRenderPlatformImage(cgImage: cgImage)
    #elseif os(macOS)
    return PolaroidRenderPlatformImage(cgImage: cgImage, size: .zero)
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
    init(platformImage: PolaroidRenderPlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #elseif os(macOS)
        self.init(nsImage: platformImage)
        #endif
    }
}
