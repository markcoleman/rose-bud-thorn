import SwiftUI
import CoreModels

public struct EntryRowCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public let type: EntryType
    public let shortText: String
    public let journalText: String
    public let photos: [PhotoRef]
    public let videos: [VideoRef]
    public let isExpanded: Bool
    public let onShortTextChange: (String) -> Void
    public let onJournalTextChange: (String) -> Void
    public let onToggleExpanded: () -> Void
    public let onAddCapture: () -> Void
    public let onRemovePhoto: (PhotoRef) -> Void
    public let onRemoveVideo: (VideoRef) -> Void
    public let photoURL: (PhotoRef) -> URL
    public let videoURL: (VideoRef) -> URL

    public init(
        type: EntryType,
        shortText: String,
        journalText: String,
        photos: [PhotoRef],
        videos: [VideoRef],
        isExpanded: Bool,
        onShortTextChange: @escaping (String) -> Void,
        onJournalTextChange: @escaping (String) -> Void,
        onToggleExpanded: @escaping () -> Void,
        onAddCapture: @escaping () -> Void,
        onRemovePhoto: @escaping (PhotoRef) -> Void,
        onRemoveVideo: @escaping (VideoRef) -> Void,
        photoURL: @escaping (PhotoRef) -> URL,
        videoURL: @escaping (VideoRef) -> URL
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                titleBadge
                Spacer()
                addCaptureButton
            }

            TextField("\(type.title) for today", text: Binding(get: { shortText }, set: onShortTextChange))
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.surface)
                )

            if !mediaItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(mediaItems) { media in
                            ZStack(alignment: .topTrailing) {
                                mediaThumbnail(media)
                                Button {
                                    removeMedia(media)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white, .black.opacity(0.65))
                                }
                                .buttonStyle(.plain)
                                .offset(x: 5, y: -5)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Button(isExpanded ? "Done" : "More…", action: onToggleExpanded)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.plain)
                .accessibilityHint("Shows additional journal details for \(type.title)")

            if isExpanded {
                TextEditor(text: Binding(get: { journalText }, set: onJournalTextChange))
                    .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 160 : 120)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(DesignTokens.surface))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(color(for: type).opacity(0.25), lineWidth: 1)
        }
        .animation(MotionTokens.smooth, value: isExpanded)
    }


    private var addCaptureButton: some View {
        Button(action: onAddCapture) {
            Image(systemName: "camera.fill")
                .imageScale(.medium)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Capture media for \(type.title)")
    }

    private var titleBadge: some View {
        Text(type.title)
            .font(.headline)
            .foregroundStyle(color(for: type))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color(for: type).opacity(0.15)))
            .accessibilityAddTraits(.isHeader)
    }

    private func color(for type: EntryType) -> Color {
        switch type {
        case .rose: return DesignTokens.rose
        case .bud: return DesignTokens.bud
        case .thorn: return DesignTokens.thorn
        }
    }

    private func mediaThumbnail(_ media: MediaItem) -> some View {
        Group {
            switch media {
            case .photo(let ref):
                PhotoThumbnailView(url: photoURL(ref), size: 56)
            case .video(let ref):
                VideoThumbnailView(url: videoURL(ref), size: 56)
            }
        }
    }

    private func removeMedia(_ media: MediaItem) {
        switch media {
        case .photo(let ref):
            onRemovePhoto(ref)
        case .video(let ref):
            onRemoveVideo(ref)
        }
    }

    private var mediaItems: [MediaItem] {
        let photoItems = photos.map(MediaItem.photo)
        let videoItems = videos.map(MediaItem.video)
        return (photoItems + videoItems).sorted { $0.createdAt < $1.createdAt }
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
