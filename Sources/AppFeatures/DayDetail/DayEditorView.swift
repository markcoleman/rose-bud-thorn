import SwiftUI
import UniformTypeIdentifiers
import CoreModels
#if DEBUG
import DocumentStore
#endif

public struct DayEditorView: View {
    @Bindable private var viewModel: DayDetailViewModel
    @State private var importerType: EntryType?
    @State private var expandedTypes: Set<EntryType> = Set(EntryType.allCases)

    public init(viewModel: DayDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    ForEach(EntryType.allCases, id: \.self) { type in
                        ReflectionBlockView(
                            type: type,
                            shortText: viewModel.entry.item(for: type).shortText,
                            journalText: viewModel.entry.item(for: type).journalTextMarkdown,
                            photos: viewModel.entry.item(for: type).photos,
                            videos: viewModel.entry.item(for: type).videos,
                            isExpanded: expandedTypes.contains(type),
                            onShortTextChange: { viewModel.updateShortText($0, for: type) },
                            onJournalTextChange: { viewModel.updateJournal($0, for: type) },
                            onToggleExpanded: {
                                toggleExpanded(type)
                            },
                            onAddCapture: { importerType = type },
                            onRemovePhoto: { ref in
                                Task { await viewModel.removePhoto(ref, for: type) }
                            },
                            onRemoveVideo: { ref in
                                Task { await viewModel.removeVideo(ref, for: type) }
                            },
                            photoURL: { viewModel.photoURL(for: $0) },
                            videoURL: { viewModel.videoURL(for: $0) }
                        )
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error) {
                            viewModel.errorMessage = nil
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.contentHorizontalPadding(for: geometry.size.width))
                .padding(.vertical, 14)
            }
            .background(DesignTokens.backgroundGradient.ignoresSafeArea())
        }
        .navigationTitle("Edit Day")
        #if !os(macOS)
        .toolbar(.visible, for: .navigationBar)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(viewModel.isSaving)
                .accessibilityIdentifier("day-editor-save-button")
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { importerType != nil },
                set: { isPresented in
                    if !isPresented {
                        importerType = nil
                    }
                }
            ),
            allowedContentTypes: [.image, .movie]
        ) { result in
            guard let type = importerType else { return }

            switch result {
            case .success(let url):
                if isMovieURL(url) {
                    Task { await viewModel.importVideo(from: url, for: type) }
                } else {
                    Task { await viewModel.importPhoto(from: url, for: type) }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }

            importerType = nil
        }
        .floatingChromeHidden()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Edit memory")
                    .font(.headline)
                    .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                Text(PresentationFormatting.localizedDayTitle(for: viewModel.dayKey))
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
            }

            Spacer(minLength: 0)

            Text(viewModel.saveFeedbackState.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(viewModel.saveFeedbackState.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(viewModel.saveFeedbackState.color.opacity(0.14))
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
        )
    }

    private func toggleExpanded(_ type: EntryType) {
        if expandedTypes.contains(type) {
            expandedTypes.remove(type)
        } else {
            expandedTypes.insert(type)
        }
    }

    private func isMovieURL(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }

        return type.conforms(to: .movie)
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
#Preview("Edit Day") {
    NavigationStack {
        DayEditorView(viewModel: makeDayEditorPreviewModel())
    }
}

@MainActor
private func makeDayEditorPreviewModel() -> DayDetailViewModel {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("DayEditorPreview-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let environment = try! AppEnvironment(configuration: DocumentStoreConfiguration(rootURL: root))
    let dayKey = LocalDayKey(isoDate: "2026-03-05", timeZoneID: "America/New_York")

    let model = DayDetailViewModel(environment: environment, dayKey: dayKey)
    var entry = EntryDay.empty(dayKey: dayKey)
    entry.roseItem.shortText = "Walked with no notifications."
    entry.budItem.shortText = "Prototype looked cleaner."
    entry.thornItem.shortText = "Lost track of lunch break."
    entry.roseItem.journalTextMarkdown = "Kept the reflection focused and quiet."
    entry.updatedAt = .now

    model.entry = entry
    model.lastSavedAt = .now
    return model
}
#endif
