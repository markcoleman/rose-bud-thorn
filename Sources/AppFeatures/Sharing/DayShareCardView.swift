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
    public let selections: [DayShareCardSelection]

    public init(dayTitle: String, selections: [DayShareCardSelection]) {
        self.dayTitle = dayTitle
        self.selections = selections
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Rose, Bud, Thorn")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                Text(dayTitle)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
            }

            HStack(alignment: .top, spacing: 16) {
                ForEach(EntryType.allCases, id: \.self) { type in
                    DayShareSelectionView(selection: selection(for: type), type: type)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    DesignTokens.surface,
                    DesignTokens.surfaceElevated
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func selection(for type: EntryType) -> DayShareCardSelection {
        selections.first(where: { $0.type == type }) ??
            DayShareCardSelection(type: type, textPreview: "", ref: nil, sourceURL: nil)
    }
}

private struct DayShareSelectionView: View {
    let selection: DayShareCardSelection
    let type: EntryType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if let sourceURL = selection.sourceURL, let image = loadPlatformImage(at: sourceURL) {
                    Image(platformImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(color(for: type).opacity(0.18))
                    VStack(spacing: 8) {
                        Image(systemName: AppIcon.mediaCount.systemName)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(color(for: type))
                        Text("No photo")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    }
                }

                Text(type.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule(style: .continuous)
                            .fill(color(for: type).opacity(0.95))
                    )
                    .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 355)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 6)

            Text(textPreview)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textPreview: String {
        let trimmed = selection.textPreview.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "No reflection captured."
        }
        return trimmed
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
