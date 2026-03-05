import SwiftUI
import CoreModels

public struct JournalDayCardView: View {
    public let summary: EntryDaySummary
    public let mode: JournalMode
    public let queryText: String
    public let category: JournalCategoryFilter
    public let photoURL: (PhotoRef) -> URL
    public let onOpen: () -> Void

    public init(
        summary: EntryDaySummary,
        mode: JournalMode,
        queryText: String,
        category: JournalCategoryFilter,
        photoURL: @escaping (PhotoRef) -> URL,
        onOpen: @escaping () -> Void
    ) {
        self.summary = summary
        self.mode = mode
        self.queryText = queryText
        self.category = category
        self.photoURL = photoURL
        self.onOpen = onOpen
    }

    public var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(PresentationFormatting.localizedDayTitle(for: summary.dayKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                        .lineLimit(1)

                    if summary.favorite {
                        Image(systemName: AppIcon.favoriteOn.systemName)
                            .foregroundStyle(.yellow)
                    }

                    Spacer(minLength: 0)

                    Text("\(summary.completionCount)/3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                }

                if !summary.previewPhotoRefs.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(summary.previewPhotoRefs.prefix(3), id: \.id) { ref in
                            PhotoThumbnailView(url: photoURL(ref), size: 52)
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(displayLines.prefix(3)) { line in
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
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DesignTokens.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("journal-day-card")
    }

    private var displayLines: [EntryDaySummary.Line] {
        let searchLines = summary.matchingLines(query: queryText, category: category)
        if mode == .search, !queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return searchLines.isEmpty ? summary.lines(for: category) : searchLines
        }

        return summary.lines(for: category)
    }

    private func color(for type: EntryType) -> Color {
        switch type {
        case .rose: return DesignTokens.rose
        case .bud: return DesignTokens.bud
        case .thorn: return DesignTokens.thorn
        }
    }
}
