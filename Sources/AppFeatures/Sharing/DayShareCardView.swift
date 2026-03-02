import SwiftUI
import CoreModels

#if os(iOS)
import UIKit
private typealias DaySharePlatformImage = UIImage
#elseif os(macOS)
import AppKit
private typealias DaySharePlatformImage = NSImage
#endif

public struct DayShareCardView: View {
    public let dayTitle: String
    public let roseURL: URL
    public let budURL: URL
    public let thornURL: URL

    public init(dayTitle: String, roseURL: URL, budURL: URL, thornURL: URL) {
        self.dayTitle = dayTitle
        self.roseURL = roseURL
        self.budURL = budURL
        self.thornURL = thornURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Rose, Bud, Thorn")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.11, green: 0.13, blue: 0.17))
                Text(dayTitle)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.19, green: 0.24, blue: 0.30))
            }

            GeometryReader { geometry in
                let leftWidth = geometry.size.width * 0.62
                let rightWidth = max(geometry.size.width - leftWidth - 16, 0)
                let rightTileHeight = max((geometry.size.height - 16) / 2, 0)

                HStack(spacing: 16) {
                    DayShareTile(url: roseURL, type: .rose)
                        .frame(width: leftWidth, height: geometry.size.height)

                    VStack(spacing: 16) {
                        DayShareTile(url: budURL, type: .bud)
                            .frame(width: rightWidth, height: rightTileHeight)
                        DayShareTile(url: thornURL, type: .thorn)
                            .frame(width: rightWidth, height: rightTileHeight)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.91),
                    Color(red: 0.92, green: 0.96, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct DayShareTile: View {
    let url: URL
    let type: EntryType

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let image = loadPlatformImage(at: url) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }

            Text(type.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .foregroundStyle(.white)
                .background(
                    Capsule(style: .continuous)
                        .fill(color(for: type).opacity(0.95))
                )
                .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func color(for type: EntryType) -> Color {
        switch type {
        case .rose:
            return DesignTokens.rose
        case .bud:
            return DesignTokens.bud
        case .thorn:
            return DesignTokens.thorn
        }
    }
}

private func loadPlatformImage(at url: URL) -> DaySharePlatformImage? {
    #if os(iOS)
    return DaySharePlatformImage(contentsOfFile: url.path)
    #elseif os(macOS)
    return DaySharePlatformImage(contentsOf: url)
    #endif
}

private extension Image {
    init(platformImage: DaySharePlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #elseif os(macOS)
        self.init(nsImage: platformImage)
        #endif
    }
}
