import SwiftUI
import CoreModels

public struct CompactJournalTodayCardView: View {
    @FocusState private var isShortTextFocused: Bool

    public let activeType: EntryType
    public let completionStates: [EntryType: Bool]
    public let promptText: String
    public let shortText: String
    public let photos: [PhotoRef]
    public let videos: [VideoRef]
    public let continueTitle: String
    public let canContinue: Bool
    public let isLocked: Bool
    public let onShortTextChange: @MainActor @Sendable (String) -> Void
    public let onSelectType: @MainActor @Sendable (EntryType) -> Void
    public let onOpenPhotoLibrary: @MainActor @Sendable () -> Void
    public let onOpenCamera: @MainActor @Sendable () -> Void
    public let onRemovePhoto: @MainActor @Sendable (PhotoRef) -> Void
    public let onRemoveVideo: @MainActor @Sendable (VideoRef) -> Void
    public let onContinue: @MainActor @Sendable () -> Void
    public let onOpenFullEditor: @MainActor @Sendable () -> Void
    public let photoURL: @MainActor @Sendable (PhotoRef) -> URL
    public let videoURL: @MainActor @Sendable (VideoRef) -> URL

    public init(
        activeType: EntryType,
        completionStates: [EntryType: Bool],
        promptText: String,
        shortText: String,
        photos: [PhotoRef],
        videos: [VideoRef],
        continueTitle: String = "Continue",
        canContinue: Bool,
        isLocked: Bool = false,
        onShortTextChange: @escaping @MainActor @Sendable (String) -> Void,
        onSelectType: @escaping @MainActor @Sendable (EntryType) -> Void,
        onOpenPhotoLibrary: @escaping @MainActor @Sendable () -> Void,
        onOpenCamera: @escaping @MainActor @Sendable () -> Void,
        onRemovePhoto: @escaping @MainActor @Sendable (PhotoRef) -> Void,
        onRemoveVideo: @escaping @MainActor @Sendable (VideoRef) -> Void,
        onContinue: @escaping @MainActor @Sendable () -> Void,
        onOpenFullEditor: @escaping @MainActor @Sendable () -> Void,
        photoURL: @escaping @MainActor @Sendable (PhotoRef) -> URL,
        videoURL: @escaping @MainActor @Sendable (VideoRef) -> URL
    ) {
        self.activeType = activeType
        self.completionStates = completionStates
        self.promptText = promptText
        self.shortText = shortText
        self.photos = photos
        self.videos = videos
        self.continueTitle = continueTitle
        self.canContinue = canContinue
        self.isLocked = isLocked
        self.onShortTextChange = onShortTextChange
        self.onSelectType = onSelectType
        self.onOpenPhotoLibrary = onOpenPhotoLibrary
        self.onOpenCamera = onOpenCamera
        self.onRemovePhoto = onRemovePhoto
        self.onRemoveVideo = onRemoveVideo
        self.onContinue = onContinue
        self.onOpenFullEditor = onOpenFullEditor
        self.photoURL = photoURL
        self.videoURL = videoURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(EntryType.allCases, id: \.self) { type in
                    typePill(for: type)
                }

                Spacer(minLength: 4)

                Button {
                    onOpenFullEditor()
                } label: {
                    Label(
                        isLocked ? "Edit" : "Details",
                        systemImage: isLocked ? AppIcon.editDay.systemName : AppIcon.navigateForward.systemName
                    )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .buttonStyle(.plain)
                .touchTargetMinSize(ControlTokens.minCompactTouchTarget)
                .accessibilityIdentifier("journal-open-full-editor-button")
            }

            Text(promptText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.96))
                .accessibilityIdentifier("journal-active-prompt")

            if isLocked {
                Text(readOnlySummaryText)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.94))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DesignTokens.journalCompactSurface)
                    )
                    .accessibilityIdentifier("journal-active-readonly-text")
            } else {
                TextField(
                    "\(activeType.title) for today",
                    text: Binding(
                        get: { shortText },
                        set: { onShortTextChange($0) }
                    )
                )
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .focused($isShortTextFocused)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DesignTokens.journalCompactSurface)
                )
            }

            if let preview = primaryPreview {
                preview
            }

            if !mediaItems.isEmpty {
                mediaStrip
            }

            if isLocked {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(DesignTokens.journalCompactProgressFill)
                    Text("Captured. Use Edit for updates.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(DesignTokens.journalCompactSurface)
                )
                .accessibilityIdentifier("journal-capture-locked-state")
            } else {
                HStack(spacing: 8) {
                    actionChip(
                        title: "Add Photo",
                        systemImage: AppIcon.addPhoto.systemName,
                        accessibilityIdentifier: "journal-add-photo-button",
                        action: onOpenPhotoLibrary
                    )

                    actionChip(
                        title: "Camera",
                        systemImage: AppIcon.camera.systemName,
                        accessibilityIdentifier: "journal-camera-button",
                        action: onOpenCamera
                    )

                    actionChip(
                        title: "Voice",
                        systemImage: "mic.fill",
                        accessibilityIdentifier: "journal-voice-button",
                        isEnabled: false,
                        action: {}
                    )
                    .accessibilityLabel("Voice, coming soon")
                }

                Button {
                    performPrimaryAction(onContinue)
                } label: {
                    Text(continueTitle)
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(canContinue ? 0.98 : 0.55))
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.journalCompactProgressFill.opacity(canContinue ? 1 : 0.45),
                                    DesignTokens.journalCompactProgressFill.opacity(canContinue ? 0.70 : 0.30)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .disabled(!canContinue)
                .accessibilityIdentifier("journal-continue-button")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DesignTokens.journalCompactSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var primaryPreview: AnyView? {
        if let photo = sortedPhotos.first {
            return AnyView(
                AsyncImage(url: photoURL(photo)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 190)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 190)
                            .clipped()
                    case .failure:
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DesignTokens.journalCompactSurface)
                            .overlay(
                                Image(systemName: "photo.badge.exclamationmark")
                                    .foregroundStyle(.white.opacity(0.72))
                            )
                            .frame(height: 190)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            )
        }

        if let video = sortedVideos.first {
            return AnyView(
                VideoThumbnailView(url: videoURL(video), size: 190)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            )
        }

        return nil
    }

    private var mediaStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(mediaItems) { item in
                    ZStack(alignment: .topTrailing) {
                        mediaThumbnail(item)
                            .frame(width: 58, height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                        if !isLocked {
                            Button {
                                removeMedia(item)
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
            }
            .padding(.vertical, 2)
        }
    }

    private var sortedPhotos: [PhotoRef] {
        photos.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString > rhs.id.uuidString
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private var sortedVideos: [VideoRef] {
        videos.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString > rhs.id.uuidString
            }
            return lhs.createdAt > rhs.createdAt
        }
    }

    private var mediaItems: [CompactMediaItem] {
        (photos.map(CompactMediaItem.photo) + videos.map(CompactMediaItem.video))
            .sorted { lhs, rhs in
                lhs.createdAt < rhs.createdAt
            }
    }

    private func mediaThumbnail(_ item: CompactMediaItem) -> some View {
        Group {
            switch item {
            case .photo(let ref):
                PhotoThumbnailView(url: photoURL(ref), size: 58)
            case .video(let ref):
                VideoThumbnailView(url: videoURL(ref), size: 58)
            }
        }
    }

    private func removeMedia(_ item: CompactMediaItem) {
        switch item {
        case .photo(let ref):
            onRemovePhoto(ref)
        case .video(let ref):
            onRemoveVideo(ref)
        }
    }

    private var readOnlySummaryText: String {
        let trimmedShortText = shortText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedShortText.isEmpty {
            return trimmedShortText
        }
        if photos.isEmpty && videos.isEmpty {
            return "No quick note captured."
        }
        return "Captured with media only."
    }

    private func typeColor(for type: EntryType) -> Color {
        switch type {
        case .rose:
            return DesignTokens.rose
        case .bud:
            return DesignTokens.bud
        case .thorn:
            return DesignTokens.thorn
        }
    }

    private func typePill(for type: EntryType) -> some View {
        let isActive = type == activeType
        let isComplete = completionStates[type] ?? false
        let color = typeColor(for: type)

        return Button {
            onSelectType(type)
            guard !isLocked else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(40))
                isShortTextFocused = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isComplete ? color : .white.opacity(0.68))
                Text(type.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(isActive ? 0.98 : 0.88))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(isActive ? 0.28 : 0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(.white.opacity(isActive ? 0.28 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .touchTargetMinSize(ControlTokens.minCompactTouchTarget)
        .accessibilityIdentifier("journal-type-pill-\(type.rawValue)")
        .accessibilityLabel("\(type.title) \(isComplete ? "complete" : "incomplete")")
    }

    private func actionChip(
        title: String,
        systemImage: String,
        accessibilityIdentifier: String,
        isEnabled: Bool = true,
        action: @escaping @MainActor () -> Void
    ) -> some View {
        Button {
            performPrimaryAction(action)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(isEnabled ? 0.93 : 0.50))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(DesignTokens.journalCompactSurface)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityIdentifier(accessibilityIdentifier)
        .touchTargetMinSize(ControlTokens.minTouchTarget)
    }

    private func performPrimaryAction(_ action: @escaping @MainActor () -> Void) {
        if isShortTextFocused {
            isShortTextFocused = false
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(120))
                action()
            }
            return
        }
        action()
    }
}

private enum CompactMediaItem: Identifiable {
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
