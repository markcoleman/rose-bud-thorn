import SwiftUI
import CoreModels

public struct EntryItemEditorView: View {
    public let type: EntryType
    public let shortText: String
    public let journalText: String
    public let photos: [PhotoRef]
    public let onShortText: (String) -> Void
    public let onJournal: (String) -> Void
    public let onAddPhoto: () -> Void
    public let onRemovePhoto: (PhotoRef) -> Void
    public let photoURL: (PhotoRef) -> URL

    public init(
        type: EntryType,
        shortText: String,
        journalText: String,
        photos: [PhotoRef],
        onShortText: @escaping (String) -> Void,
        onJournal: @escaping (String) -> Void,
        onAddPhoto: @escaping () -> Void,
        onRemovePhoto: @escaping (PhotoRef) -> Void,
        photoURL: @escaping (PhotoRef) -> URL
    ) {
        self.type = type
        self.shortText = shortText
        self.journalText = journalText
        self.photos = photos
        self.onShortText = onShortText
        self.onJournal = onJournal
        self.onAddPhoto = onAddPhoto
        self.onRemovePhoto = onRemovePhoto
        self.photoURL = photoURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(type.title)
                    .font(.headline)
                Spacer()
                Button(action: onAddPhoto) {
                    Label("Add Photo", systemImage: "photo.badge.plus")
                }
                .buttonStyle(.bordered)
            }

            TextField("Short reflection", text: Binding(get: { shortText }, set: onShortText))
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.surface)
                )

            TextEditor(text: Binding(get: { journalText }, set: onJournal))
                .frame(minHeight: 120)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))

            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(photos) { ref in
                            VStack(spacing: 4) {
                                PhotoThumbnailView(url: photoURL(ref), size: 60)
                                Button(role: .destructive) {
                                    onRemovePhoto(ref)
                                } label: {
                                    Text("Remove")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(DesignTokens.surfaceElevated))
    }
}
