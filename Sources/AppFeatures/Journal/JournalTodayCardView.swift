import SwiftUI
import CoreModels

public struct JournalTodayCardView: View {
    public let entry: EntryDay
    public let isSaving: Bool
    public let lastSavedAt: Date?
    public let todayMatchesSearch: Bool
    public let onShortTextChange: (EntryType, String) -> Void
    public let onAddPhoto: (EntryType) -> Void
    public let onFavoriteChange: (Bool) -> Void
    public let photoURL: (PhotoRef) -> URL

    public init(
        entry: EntryDay,
        isSaving: Bool,
        lastSavedAt: Date?,
        todayMatchesSearch: Bool,
        onShortTextChange: @escaping (EntryType, String) -> Void,
        onAddPhoto: @escaping (EntryType) -> Void,
        onFavoriteChange: @escaping (Bool) -> Void,
        photoURL: @escaping (PhotoRef) -> URL
    ) {
        self.entry = entry
        self.isSaving = isSaving
        self.lastSavedAt = lastSavedAt
        self.todayMatchesSearch = todayMatchesSearch
        self.onShortTextChange = onShortTextChange
        self.onAddPhoto = onAddPhoto
        self.onFavoriteChange = onFavoriteChange
        self.photoURL = photoURL
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.headline)
                        .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                    Text(Date.now.formatted(date: .complete, time: .omitted))
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                }

                Spacer(minLength: 0)

                Toggle(isOn: Binding(
                    get: { entry.favorite },
                    set: { onFavoriteChange($0) }
                )) {
                    Image(systemName: entry.favorite ? AppIcon.favoriteOn.systemName : AppIcon.favoriteOff.systemName)
                        .foregroundStyle(entry.favorite ? Color.yellow : DesignTokens.textSecondaryOnSurface)
                }
                .labelsHidden()
                .toggleStyle(.switch)
            }

            completionSegments

            if todayMatchesSearch {
                Label("Today matches search", systemImage: AppIcon.sectionSearch.systemName)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
            }

            ForEach(EntryType.allCases, id: \.self) { type in
                row(for: type)
            }

            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                } else if let lastSavedAt {
                    Text("Saved \(lastSavedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var completionSegments: some View {
        HStack(spacing: 8) {
            ForEach(EntryType.allCases, id: \.self) { type in
                let isComplete = !entry.item(for: type).shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    !entry.item(for: type).journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    !entry.item(for: type).photos.isEmpty ||
                    !entry.item(for: type).videos.isEmpty

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color(for: type).opacity(isComplete ? 0.9 : 0.2))
                    .frame(height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Today's progress")
        .accessibilityIdentifier("today-completion-progress")
    }

    private func row(for type: EntryType) -> some View {
        let item = entry.item(for: type)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                TextField(
                    "\(type.title) for today",
                    text: Binding(
                        get: { item.shortText },
                        set: { onShortTextChange(type, $0) }
                    )
                )
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DesignTokens.surface)
                )

                Button {
                    onAddPhoto(type)
                } label: {
                    Image(systemName: AppIcon.camera.systemName)
                        .font(.headline)
                        .foregroundStyle(color(for: type))
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(color(for: type).opacity(0.16))
                        )
                }
                .buttonStyle(.plain)
                .touchTargetMinSize(ControlTokens.minTouchTarget)
                .accessibilityLabel("Capture media for \(type.title)")
            }

            if !item.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(item.photos.prefix(3), id: \.id) { ref in
                            PhotoThumbnailView(url: photoURL(ref), size: 42)
                                .frame(width: 42, height: 42)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
        }
    }

    private func color(for type: EntryType) -> Color {
        switch type {
        case .rose: return DesignTokens.rose
        case .bud: return DesignTokens.bud
        case .thorn: return DesignTokens.thorn
        }
    }
}
