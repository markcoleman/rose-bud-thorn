import SwiftUI
import CoreModels

public struct EntryRowCard: View {
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
            HStack(spacing: 10) {
                Text(type.title)
                    .font(.headline)
                    .foregroundStyle(color(for: type))
                    .frame(width: 56, alignment: .leading)

                TextField("\(type.title) for today", text: Binding(get: { shortText }, set: onShortTextChange))
                    .textFieldStyle(.roundedBorder)

                Button(action: onAddPhoto) {
                    Image(systemName: "camera.fill")
                        .imageScale(.medium)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Add photo to \(type.title)")
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

            if isExpanded {
                TextEditor(text: Binding(get: { journalText }, set: onJournalTextChange))
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
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

    private func color(for type: EntryType) -> Color {
        switch type {
        case .rose: return DesignTokens.rose
        case .bud: return DesignTokens.bud
        case .thorn: return DesignTokens.thorn
        }
    }
}
