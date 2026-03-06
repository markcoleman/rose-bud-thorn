import SwiftUI
import CoreModels

public enum ReflectionBlockState: Sendable, Equatable {
    case empty
    case drafting
    case hasText
    case hasPhoto
    case complete
}

public struct ReflectionBlockView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public let type: EntryType
    public let shortText: String
    public let journalText: String
    public let photos: [PhotoRef]
    public let videos: [VideoRef]
    public let isExpanded: Bool
    public let onShortTextChange: @MainActor @Sendable (String) -> Void
    public let onJournalTextChange: @MainActor @Sendable (String) -> Void
    public let onToggleExpanded: @MainActor @Sendable () -> Void
    public let onAddCapture: @MainActor @Sendable () -> Void
    public let onRemovePhoto: @MainActor @Sendable (PhotoRef) -> Void
    public let onRemoveVideo: @MainActor @Sendable (VideoRef) -> Void
    public let photoURL: @MainActor @Sendable (PhotoRef) -> URL
    public let videoURL: @MainActor @Sendable (VideoRef) -> URL

    public init(
        type: EntryType,
        shortText: String,
        journalText: String,
        photos: [PhotoRef],
        videos: [VideoRef],
        isExpanded: Bool,
        onShortTextChange: @escaping @MainActor @Sendable (String) -> Void,
        onJournalTextChange: @escaping @MainActor @Sendable (String) -> Void,
        onToggleExpanded: @escaping @MainActor @Sendable () -> Void,
        onAddCapture: @escaping @MainActor @Sendable () -> Void,
        onRemovePhoto: @escaping @MainActor @Sendable (PhotoRef) -> Void,
        onRemoveVideo: @escaping @MainActor @Sendable (VideoRef) -> Void,
        photoURL: @escaping @MainActor @Sendable (PhotoRef) -> URL,
        videoURL: @escaping @MainActor @Sendable (VideoRef) -> URL
    ) {
        self.type = type
        self.shortText = shortText
        self.journalText = journalText
        self.photos = photos
        self.videos = videos
        self.isExpanded = isExpanded
        self.onShortTextChange = onShortTextChange
        self.onJournalTextChange = onJournalTextChange
        self.onToggleExpanded = onToggleExpanded
        self.onAddCapture = onAddCapture
        self.onRemovePhoto = onRemovePhoto
        self.onRemoveVideo = onRemoveVideo
        self.photoURL = photoURL
        self.videoURL = videoURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            header

            TextField(
                "\(type.title) for today",
                text: Binding(
                    get: { shortText },
                    set: { onShortTextChange($0) }
                )
            )
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .frame(minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DesignTokens.surface)
            )

            if !mediaItems.isEmpty {
                mediaStrip
            }

            if isExpanded {
                TextEditor(
                    text: Binding(
                        get: { journalText },
                        set: { onJournalTextChange($0) }
                    )
                )
                .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 152 : 112)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DesignTokens.surface)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(typeColor.opacity(0.25), lineWidth: 1)
        )
        .animation(MotionTokens.smooth, value: isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(type.title) block")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(type.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(typeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(typeColor.opacity(0.16))
                )

            statePill

            Spacer(minLength: 4)

            Button {
                onAddCapture()
            } label: {
                Label(mediaItems.isEmpty ? "Add" : "Replace", systemImage: AppIcon.camera.systemName)
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(typeColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(typeColor.opacity(0.18))
                    )
            }
            .buttonStyle(.plain)
            .touchTargetMinSize(ControlTokens.minTouchTarget)
            .accessibilityLabel("Capture media for \(type.title)")

            Button(isExpanded ? "Done" : "More") {
                onToggleExpanded()
            }
            .font(.footnote.weight(.semibold))
            .buttonStyle(.plain)
            .touchTargetMinSize(ControlTokens.minCompactTouchTarget)
            .accessibilityLabel("\(isExpanded ? "Collapse" : "Expand") \(type.title) details")
        }
    }

    private var mediaStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(mediaItems) { media in
                    ZStack(alignment: .topTrailing) {
                        mediaThumbnail(media)
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                        Button {
                            removeMedia(media)
                        } label: {
                            Image(systemName: AppIcon.closeCircle.systemName)
                                .font(.system(size: 16))
                                .foregroundStyle(.white, .black.opacity(0.68))
                        }
                        .buttonStyle(.plain)
                        .touchTargetMinSize(ControlTokens.minCompactTouchTarget)
                        .offset(x: 5, y: -5)
                        .accessibilityLabel("Remove media")
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var statePill: some View {
        let state = blockState
        return Text(state.title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(state.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(state.color.opacity(0.14))
            )
            .accessibilityLabel("\(type.title) is \(state.title)")
    }

    private var blockState: ReflectionBlockState {
        let hasShort = !shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasJournal = !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasMedia = !mediaItems.isEmpty

        if hasShort && hasJournal && hasMedia {
            return .complete
        }
        if hasMedia {
            return .hasPhoto
        }
        if hasShort && hasJournal {
            return .hasText
        }
        if hasShort || hasJournal {
            return .drafting
        }
        return .empty
    }

    private var typeColor: Color {
        switch type {
        case .rose:
            return DesignTokens.rose
        case .bud:
            return DesignTokens.bud
        case .thorn:
            return DesignTokens.thorn
        }
    }

    private var mediaItems: [MediaItem] {
        let photoItems = photos.map(MediaItem.photo)
        let videoItems = videos.map(MediaItem.video)

        return (photoItems + videoItems).sorted { lhs, rhs in
            lhs.createdAt < rhs.createdAt
        }
    }

    private func mediaThumbnail(_ item: MediaItem) -> some View {
        Group {
            switch item {
            case .photo(let ref):
                PhotoThumbnailView(url: photoURL(ref), size: 58)
            case .video(let ref):
                VideoThumbnailView(url: videoURL(ref), size: 58)
            }
        }
    }

    private func removeMedia(_ item: MediaItem) {
        switch item {
        case .photo(let ref):
            onRemovePhoto(ref)
        case .video(let ref):
            onRemoveVideo(ref)
        }
    }
}

private enum MediaItem: Identifiable {
    case photo(PhotoRef)
    case video(VideoRef)

    var id: UUID {
        switch self {
        case .photo(let ref):
            return ref.id
        case .video(let ref):
            return ref.id
        }
    }

    var createdAt: Date {
        switch self {
        case .photo(let ref):
            return ref.createdAt
        case .video(let ref):
            return ref.createdAt
        }
    }
}

private extension ReflectionBlockState {
    var title: String {
        switch self {
        case .empty:
            return "Empty"
        case .drafting:
            return "Draft"
        case .hasText:
            return "Text"
        case .hasPhoto:
            return "Photo"
        case .complete:
            return "Complete"
        }
    }

    var color: Color {
        switch self {
        case .empty:
            return DesignTokens.textSecondaryOnSurface
        case .drafting:
            return DesignTokens.accent
        case .hasText:
            return DesignTokens.accent
        case .hasPhoto:
            return DesignTokens.warning
        case .complete:
            return DesignTokens.success
        }
    }
}
