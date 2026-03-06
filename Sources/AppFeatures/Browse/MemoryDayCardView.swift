import SwiftUI
import CoreModels

public struct MemoryDayCardView: View {
    public let snapshot: BrowseDaySnapshot
    public let thumbnailURLs: [URL]
    public let isShareInProgress: Bool
    public let onOpen: () -> Void
    public let onShare: () -> Void

    public init(
        snapshot: BrowseDaySnapshot,
        thumbnailURLs: [URL] = [],
        isShareInProgress: Bool = false,
        onOpen: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self.snapshot = snapshot
        self.thumbnailURLs = Array(thumbnailURLs.prefix(3))
        self.isShareInProgress = isShareInProgress
        self.onOpen = onOpen
        self.onShare = onShare
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    feedPreview
                    emotionalStrip
                    previewRows
                    metadataRow
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(MemoryCardPressStyle())

            footer
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier("browse-timeline-card")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(PresentationFormatting.localizedDayTitle(for: snapshot.dayKey))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text("\(snapshot.completionCount)/3")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(DesignTokens.surface))
        }
    }

    private var feedPreview: some View {
        ZStack(alignment: .bottomTrailing) {
            heroImage
            if secondaryThumbnailURLs.count > 0 {
                HStack(spacing: 6) {
                    ForEach(Array(secondaryThumbnailURLs.enumerated()), id: \.offset) { _, url in
                        thumbnailImage(url: url)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 166)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(thumbnailURLs.isEmpty ? "No timeline image" : "Timeline image")
        .accessibilityIdentifier("browse-feed-thumbnail")
    }

    private var heroImage: some View {
        Group {
            if let heroURL = heroThumbnailURL {
                AsyncImage(url: heroURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderThumbnail
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderThumbnail
                    @unknown default:
                        placeholderThumbnail
                    }
                }
            } else {
                placeholderThumbnail
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.surface)
        .clipped()
    }

    private func thumbnailImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                placeholderThumbnail
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholderThumbnail
            @unknown default:
                placeholderThumbnail
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }

    private var emotionalStrip: some View {
        HStack(spacing: 6) {
            stripBlock(color: DesignTokens.rose, isActive: snapshot.hasRoseContent)
            stripBlock(color: DesignTokens.bud, isActive: snapshot.hasBudContent)
            stripBlock(color: DesignTokens.thorn, isActive: snapshot.hasThornContent)
        }
    }

    private func stripBlock(color: Color, isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color.opacity(isActive ? 0.95 : 0.2))
            .frame(height: 8)
            .accessibilityHidden(true)
    }

    private var previewRows: some View {
        VStack(alignment: .leading, spacing: 7) {
            previewRow(symbol: "r.circle.fill", text: snapshot.rosePreview, color: DesignTokens.rose)
            previewRow(symbol: "b.circle.fill", text: snapshot.budPreview, color: DesignTokens.bud)
            previewRow(symbol: "t.circle.fill", text: snapshot.thornPreview, color: DesignTokens.thorn)
        }
    }

    @ViewBuilder
    private func previewRow(symbol: String, text: String, color: Color) -> some View {
        if !text.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: symbol)
                    .font(.caption)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                    .lineLimit(2)
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 10) {
            if let mood = snapshot.mood {
                Label("\(mood)/5", systemImage: AppIcon.mood.systemName)
                    .labelStyle(.titleAndIcon)
            }

            if snapshot.hasMedia {
                Label("\(snapshot.mediaCount)", systemImage: AppIcon.mediaCount.systemName)
                    .labelStyle(.titleAndIcon)
            }

            if !snapshot.tags.isEmpty {
                Text(snapshot.tags.prefix(3).map { "#\($0)" }.joined(separator: " "))
                    .lineLimit(1)
            }
        }
        .font(.caption)
        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: onOpen) {
                Label("View Day", systemImage: AppIcon.navigateForward.systemName)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .touchTargetMinSize(ControlTokens.minTouchTarget)

            Button(action: onShare) {
                if isShareInProgress {
                    ProgressView()
                        .frame(width: 22, height: 22)
                } else {
                    Image(systemName: AppIcon.shareExport.systemName)
                        .font(.body.weight(.semibold))
                }
            }
            .buttonStyle(.bordered)
            .touchTargetMinSize(ControlTokens.minTouchTarget)
            .disabled(isShareInProgress)
            .accessibilityLabel("Share day")
            .accessibilityIdentifier("browse-timeline-share-button")
        }
    }

    private var heroThumbnailURL: URL? {
        thumbnailURLs.first
    }

    private var secondaryThumbnailURLs: [URL] {
        Array(thumbnailURLs.dropFirst().prefix(2))
    }

    private var accessibilitySummary: String {
        let moodText = snapshot.mood.map { "Mood \($0) out of 5." } ?? ""
        let mediaText = snapshot.hasMedia ? "\(snapshot.mediaCount) media items." : "No media."
        return "\(PresentationFormatting.localizedDayTitle(for: snapshot.dayKey)). \(snapshot.completionCount) of 3 reflections completed. \(moodText) \(mediaText)"
    }

    private var placeholderThumbnail: some View {
        ZStack {
            LinearGradient(
                colors: [DesignTokens.surface, DesignTokens.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: AppIcon.mediaCount.systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(DesignTokens.textSecondaryOnSurface)
        }
    }
}

private struct MemoryCardPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .animation(reduceMotion ? nil : MotionTokens.quick, value: configuration.isPressed)
    }
}
