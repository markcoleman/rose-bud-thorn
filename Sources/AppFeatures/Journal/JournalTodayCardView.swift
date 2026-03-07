import SwiftUI
import CoreModels

public struct JournalTodayCardView: View {
    public let entry: EntryDay
    public let saveFeedbackState: JournalSaveFeedbackState
    public let onShortTextChange: @MainActor @Sendable (EntryType, String) -> Void
    public let onJournalTextChange: @MainActor @Sendable (EntryType, String) -> Void
    public let onOpenPhotoLibrary: @MainActor @Sendable (EntryType) -> Void
    public let onOpenCamera: @MainActor @Sendable (EntryType) -> Void
    public let onRemovePhoto: @MainActor @Sendable (EntryType, PhotoRef) -> Void
    public let onRemoveVideo: @MainActor @Sendable (EntryType, VideoRef) -> Void
    public let onOpenCompletedDay: @MainActor @Sendable () -> Void
    public let photoURL: @MainActor @Sendable (PhotoRef) -> URL
    public let videoURL: @MainActor @Sendable (VideoRef) -> URL

    @State private var expandedTypes: Set<EntryType> = []

    public init(
        entry: EntryDay,
        saveFeedbackState: JournalSaveFeedbackState,
        onShortTextChange: @escaping @MainActor @Sendable (EntryType, String) -> Void,
        onJournalTextChange: @escaping @MainActor @Sendable (EntryType, String) -> Void,
        onOpenPhotoLibrary: @escaping @MainActor @Sendable (EntryType) -> Void,
        onOpenCamera: @escaping @MainActor @Sendable (EntryType) -> Void,
        onRemovePhoto: @escaping @MainActor @Sendable (EntryType, PhotoRef) -> Void,
        onRemoveVideo: @escaping @MainActor @Sendable (EntryType, VideoRef) -> Void,
        onOpenCompletedDay: @escaping @MainActor @Sendable () -> Void,
        photoURL: @escaping @MainActor @Sendable (PhotoRef) -> URL,
        videoURL: @escaping @MainActor @Sendable (VideoRef) -> URL
    ) {
        self.entry = entry
        self.saveFeedbackState = saveFeedbackState
        self.onShortTextChange = onShortTextChange
        self.onJournalTextChange = onJournalTextChange
        self.onOpenPhotoLibrary = onOpenPhotoLibrary
        self.onOpenCamera = onOpenCamera
        self.onRemovePhoto = onRemovePhoto
        self.onRemoveVideo = onRemoveVideo
        self.onOpenCompletedDay = onOpenCompletedDay
        self.photoURL = photoURL
        self.videoURL = videoURL
    }

    public var body: some View {
        Group {
            if entry.isCompleteForDailyCapture {
                completedTodayCard
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            } else {
                composer
                    .transition(.asymmetric(insertion: .opacity, removal: .scale.combined(with: .opacity)))
            }
        }
        .animation(MotionTokens.smooth, value: entry.isCompleteForDailyCapture)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.headline)
                        .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                    Text(Date.now.formatted(date: .complete, time: .omitted))
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                }

                Spacer(minLength: 0)

                saveStatusPill
            }

            progressRow

            ForEach(EntryType.allCases, id: \.self) { type in
                let item = entry.item(for: type)

                ReflectionBlockView(
                    type: type,
                    shortText: item.shortText,
                    journalText: item.journalTextMarkdown,
                    photos: item.photos,
                    videos: item.videos,
                    isExpanded: expandedTypes.contains(type),
                    onShortTextChange: { onShortTextChange(type, $0) },
                    onJournalTextChange: { onJournalTextChange(type, $0) },
                    onToggleExpanded: {
                        toggleExpanded(type)
                    },
                    onOpenPhotoLibrary: { onOpenPhotoLibrary(type) },
                    onOpenCamera: { onOpenCamera(type) },
                    onRemovePhoto: { onRemovePhoto(type, $0) },
                    onRemoveVideo: { onRemoveVideo(type, $0) },
                    photoURL: photoURL,
                    videoURL: videoURL
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
        )
    }

    private var completedTodayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            JournalMemoryCardView(
                dayTitle: "Today",
                statusText: saveFeedbackState.completedLabel,
                completionCount: entry.completionCount,
                previewPhotoURLs: previewPhotoURLs,
                lines: summaryLines,
                emphasis: .todayComplete,
                onOpen: onOpenCompletedDay
            )
            .accessibilityIdentifier("journal-today-complete-card")
        }
    }

    private var progressRow: some View {
        HStack(spacing: 8) {
            ForEach(EntryType.allCases, id: \.self) { type in
                let isComplete = entry.item(for: type).hasAnyContent
                HStack(spacing: 6) {
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isComplete ? color(for: type) : DesignTokens.textSecondaryOnSurface)

                    Text(type.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color(for: type).opacity(isComplete ? 0.20 : 0.10))
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today progress \(entry.completionCount) of 3")
        .accessibilityIdentifier("today-completion-progress")
    }

    private var saveStatusPill: some View {
        Text(saveFeedbackState.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(saveFeedbackState.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(saveFeedbackState.color.opacity(0.14))
            )
            .accessibilityLabel(saveFeedbackState.label)
    }

    private var summaryLines: [EntryDaySummary.Line] {
        EntryType.allCases.compactMap { type in
            let item = entry.item(for: type)
            let text = item.shortText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                return EntryDaySummary.Line(type: type, text: String(text.prefix(120)))
            }

            let journal = item.journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
            if !journal.isEmpty {
                return EntryDaySummary.Line(type: type, text: String(journal.prefix(120)))
            }

            return nil
        }
    }

    private var previewPhotoURLs: [URL] {
        let refs = [entry.roseItem.photos, entry.budItem.photos, entry.thornItem.photos]
            .flatMap { $0 }
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id.uuidString > rhs.id.uuidString
                }
                return lhs.createdAt > rhs.createdAt
            }

        return refs.prefix(3).map(photoURL)
    }

    private func toggleExpanded(_ type: EntryType) {
        if expandedTypes.contains(type) {
            expandedTypes.remove(type)
        } else {
            expandedTypes.insert(type)
        }
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

private extension JournalSaveFeedbackState {
    var label: String {
        switch self {
        case .draft:
            return "Draft"
        case .saving:
            return "Saving"
        case .saved(let date):
            return date.relativeSaveLabel
        case .complete:
            return "Complete"
        }
    }

    var completedLabel: String? {
        switch self {
        case .complete(let date):
            return date?.relativeSaveLabel ?? "Complete"
        case .saved(let date):
            return date.relativeSaveLabel
        case .saving:
            return "Saving"
        case .draft:
            return "Draft"
        }
    }

    var color: Color {
        switch self {
        case .draft:
            return DesignTokens.textSecondaryOnSurface
        case .saving:
            return DesignTokens.warning
        case .saved:
            return DesignTokens.accent
        case .complete:
            return DesignTokens.success
        }
    }
}

private extension Date {
    var relativeSaveLabel: String {
        let elapsed = max(0, Int(Date.now.timeIntervalSince(self)))
        if elapsed < 10 {
            return "Saved just now"
        }
        if elapsed < 60 {
            return "Saved \(elapsed)s ago"
        }
        let minutes = elapsed / 60
        if minutes < 60 {
            return "Saved \(minutes)m ago"
        }
        return "Saved \(formatted(date: .omitted, time: .shortened))"
    }
}

#if DEBUG
#Preview("Today Empty") {
    JournalTodayCardView(
        entry: EntryDay.empty(dayKey: LocalDayKey(isoDate: "2026-03-06", timeZoneID: "America/New_York")),
        saveFeedbackState: .draft,
        onShortTextChange: { _, _ in },
        onJournalTextChange: { _, _ in },
        onOpenPhotoLibrary: { _ in },
        onOpenCamera: { _ in },
        onRemovePhoto: { _, _ in },
        onRemoveVideo: { _, _ in },
        onOpenCompletedDay: {},
        photoURL: { _ in URL(fileURLWithPath: "/tmp/placeholder.jpg") },
        videoURL: { _ in URL(fileURLWithPath: "/tmp/placeholder.mov") }
    )
    .padding()
    .background(DesignTokens.backgroundGradient)
}

#Preview("Today Partial") {
    var entry = EntryDay.empty(dayKey: LocalDayKey(isoDate: "2026-03-06", timeZoneID: "America/New_York"))
    entry.roseItem.shortText = "Quiet sunrise walk"
    entry.roseItem.updatedAt = .now
    entry.updatedAt = .now

    return JournalTodayCardView(
        entry: entry,
        saveFeedbackState: .saved(.now),
        onShortTextChange: { _, _ in },
        onJournalTextChange: { _, _ in },
        onOpenPhotoLibrary: { _ in },
        onOpenCamera: { _ in },
        onRemovePhoto: { _, _ in },
        onRemoveVideo: { _, _ in },
        onOpenCompletedDay: {},
        photoURL: { _ in URL(fileURLWithPath: "/tmp/placeholder.jpg") },
        videoURL: { _ in URL(fileURLWithPath: "/tmp/placeholder.mov") }
    )
    .padding()
    .background(DesignTokens.backgroundGradient)
}

#Preview("Today Complete") {
    var entry = EntryDay.empty(dayKey: LocalDayKey(isoDate: "2026-03-06", timeZoneID: "America/New_York"))
    entry.roseItem.shortText = "Quiet sunrise walk"
    entry.budItem.shortText = "Sketching product ideas"
    entry.thornItem.shortText = "Afternoon slump"
    entry.roseItem.updatedAt = .now
    entry.budItem.updatedAt = .now
    entry.thornItem.updatedAt = .now
    entry.updatedAt = .now

    return JournalTodayCardView(
        entry: entry,
        saveFeedbackState: .complete(.now),
        onShortTextChange: { _, _ in },
        onJournalTextChange: { _, _ in },
        onOpenPhotoLibrary: { _ in },
        onOpenCamera: { _ in },
        onRemovePhoto: { _, _ in },
        onRemoveVideo: { _, _ in },
        onOpenCompletedDay: {},
        photoURL: { _ in URL(fileURLWithPath: "/tmp/placeholder.jpg") },
        videoURL: { _ in URL(fileURLWithPath: "/tmp/placeholder.mov") }
    )
    .padding()
    .background(DesignTokens.backgroundGradient)
}
#endif
