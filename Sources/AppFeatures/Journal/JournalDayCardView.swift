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
        JournalMemoryCardView(
            dayTitle: PresentationFormatting.localizedDayTitle(for: summary.dayKey),
            statusText: nil,
            completionCount: summary.completionCount,
            favorite: summary.favorite,
            previewPhotoURLs: summary.previewPhotoRefs.prefix(3).map { photoURL($0) },
            lines: displayLines,
            emphasis: .timeline,
            onOpen: onOpen
        )
    }

    private var displayLines: [EntryDaySummary.Line] {
        let searchLines = summary.matchingLines(query: queryText, category: category)
        if mode == .search, !queryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return searchLines.isEmpty ? summary.lines(for: category) : searchLines
        }

        return summary.lines(for: category)
    }
}
