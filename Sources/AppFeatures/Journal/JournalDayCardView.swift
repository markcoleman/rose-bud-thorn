import SwiftUI
import CoreModels

public struct JournalDayCardView: View {
    public let summary: EntryDaySummary
    public let photoURL: (PhotoRef) -> URL
    public let onOpen: () -> Void

    public init(
        summary: EntryDaySummary,
        photoURL: @escaping (PhotoRef) -> URL,
        onOpen: @escaping () -> Void
    ) {
        self.summary = summary
        self.photoURL = photoURL
        self.onOpen = onOpen
    }

    public var body: some View {
        JournalMemoryCardView(
            dayTitle: PresentationFormatting.localizedDayTitle(for: summary.dayKey),
            statusText: nil,
            completionCount: summary.completionCount,
            previewPhotoURLs: summary.previewPhotoRefs.prefix(3).map { photoURL($0) },
            lines: summary.lines(),
            emphasis: .timeline,
            onOpen: onOpen
        )
    }
}
