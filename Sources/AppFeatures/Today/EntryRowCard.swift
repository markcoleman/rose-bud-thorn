import SwiftUI
import CoreModels

public struct EntryRowCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public let type: EntryType
    public let shortText: String
    public let journalText: String
    public let photos: [PhotoRef]
    public let isExpanded: Bool
    public let onShortTextChange: (String) -> Void
    public let onJournalTextChange: (String) -> Void
    public let onToggleExpanded: () -> Void
    public let onAddPhoto: () -> Void
    public let onRemovePhoto: (PhotoRef) -> Void
    public let photoURL: (PhotoRef) -> URL

    public init(
        type: EntryType,
        shortText: String,
        journalText: String,
        photos: [PhotoRef],
        isExpanded: Bool,
        onShortTextChange: @escaping (String) -> Void,
        onJournalTextChange: @escaping (String) -> Void,
        onToggleExpanded: @escaping () -> Void,
        onAddPhoto: @escaping () -> Void,
        onRemovePhoto: @escaping (PhotoRef) -> Void,
        photoURL: @escaping (PhotoRef) -> URL
    ) {
        self.type = type
        self.shortText = shortText
        self.journalText = journalText
        self.photos = photos
        self.isExpanded = isExpanded
        self.onShortTextChange = onShortTextChange
        self.onJournalTextChange = onJournalTextChange
        self.onToggleExpanded = onToggleExpanded
        self.onAddPhoto = onAddPhoto
        self.onRemovePhoto = onRemovePhoto
        self.photoURL = photoURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits {
                HStack(spacing: 10) {
                    titleBadge

                    TextField("\(type.title) for today", text: Binding(get: { shortText }, set: onShortTextChange))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(DesignTokens.surface)
                        )

                    addPhotoButton
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        titleBadge
                        Spacer()
                        addPhotoButton
                    }

                    TextField("\(type.title) for today", text: Binding(get: { shortText }, set: onShortTextChange))
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(DesignTokens.surface)
                        )
                }
            }

            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos) { ref in
                            ZStack(alignment: .topTrailing) {
                                PhotoThumbnailView(url: photoURL(ref), size: 56)
                                Button {
                                    onRemovePhoto(ref)
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


    private var addPhotoButton: some View {
        Button(action: onAddPhoto) {
            Image(systemName: "camera.fill")
                .imageScale(.medium)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Add photo to \(type.title)")
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
}
