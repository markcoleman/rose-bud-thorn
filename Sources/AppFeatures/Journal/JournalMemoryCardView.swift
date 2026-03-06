import SwiftUI
import CoreModels

public struct JournalMemoryCardView: View {
    public enum Emphasis: Sendable, Equatable {
        case timeline
        case todayComplete
    }

    public let dayTitle: String
    public let statusText: String?
    public let completionCount: Int
    public let favorite: Bool
    public let previewPhotoURLs: [URL]
    public let lines: [EntryDaySummary.Line]
    public let emphasis: Emphasis
    public let onOpen: () -> Void

    public init(
        dayTitle: String,
        statusText: String?,
        completionCount: Int,
        favorite: Bool,
        previewPhotoURLs: [URL],
        lines: [EntryDaySummary.Line],
        emphasis: Emphasis = .timeline,
        onOpen: @escaping () -> Void
    ) {
        self.dayTitle = dayTitle
        self.statusText = statusText
        self.completionCount = completionCount
        self.favorite = favorite
        self.previewPhotoURLs = previewPhotoURLs
        self.lines = lines
        self.emphasis = emphasis
        self.onOpen = onOpen
    }

    public var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .topLeading) {
                if emphasis == .todayComplete {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DesignTokens.surfaceElevated.opacity(0.45))
                        .offset(x: 0, y: 5)
                }

                cardContent
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("journal-day-card")
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                    .lineLimit(1)

                if favorite {
                    Image(systemName: AppIcon.favoriteOn.systemName)
                        .foregroundStyle(.yellow)
                }

                Spacer(minLength: 0)

                Text("\(completionCount)/3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous)
                            .fill(DesignTokens.surface)
                    )
            }

            if let statusText {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.success)
                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                }
            }

            if !previewPhotoURLs.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(previewPhotoURLs.prefix(3).enumerated()), id: \.offset) { _, url in
                        PhotoThumbnailView(url: url, size: 58)
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(lines.prefix(3)) { line in
                    HStack(alignment: .top, spacing: 7) {
                        Circle()
                            .fill(color(for: line.type))
                            .frame(width: 7, height: 7)
                            .padding(.top, 5)

                        Text(line.text)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                    }
                }

                if lines.isEmpty {
                    Text("No reflection text yet")
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
        )
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

#if DEBUG
#Preview("Past Memory Card") {
    let lines = [
        EntryDaySummary.Line(type: .rose, text: "Great coffee and good focus"),
        EntryDaySummary.Line(type: .bud, text: "New idea for the side project"),
        EntryDaySummary.Line(type: .thorn, text: "Long commute drained energy")
    ]

    return JournalMemoryCardView(
        dayTitle: "Tuesday, March 3",
        statusText: nil,
        completionCount: 3,
        favorite: true,
        previewPhotoURLs: [],
        lines: lines,
        emphasis: .timeline,
        onOpen: {}
    )
    .padding()
    .background(DesignTokens.backgroundGradient)
}
#endif
