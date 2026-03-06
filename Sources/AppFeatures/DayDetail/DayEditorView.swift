import SwiftUI
import UniformTypeIdentifiers
import CoreModels
#if os(iOS) && !targetEnvironment(macCatalyst)
import PhotosUI
#endif
#if DEBUG
import DocumentStore
#endif

public struct DayEditorView: View {
    @Bindable private var viewModel: DayDetailViewModel
    @State private var importerRequest: ImportRequest?
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var cameraRequest: CameraCaptureRequest?
    @State private var libraryImportRequest: LibraryImportRequest?
    @State private var isPhotoLibraryPresented = false
    @State private var selectedPhotoLibraryItem: PhotosPickerItem?
    #endif
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
                            onOpenPhotoLibrary: {
                                presentPhotoLibrary(for: type)
                            },
                            onOpenCamera: {
                                presentCameraCapture(for: type)
                            },
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
                get: { importerRequest != nil },
                set: { isPresented in
                    if !isPresented {
                        importerRequest = nil
                    }
                }
            ),
            allowedContentTypes: importerAllowedTypes
        ) { result in
            guard let request = importerRequest else { return }

            switch result {
            case .success(let url):
                if isMovieURL(url) {
                    Task { await viewModel.importVideo(from: url, for: request.type) }
                } else {
                    Task { await viewModel.importPhoto(from: url, for: request.type) }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
            }

            importerRequest = nil
        }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        .fullScreenCover(item: $cameraRequest) { request in
            MomentCameraView(
                entryType: request.type,
                onFallbackImport: {
                    importerRequest = ImportRequest(type: request.type, includeMovies: true)
                },
                onPickFromLibrary: {
                    presentPhotoLibrary(for: request.type)
                },
                onConfirm: { draft in
                    await persist(draft: draft, request: request)
                }
            )
        }
        .photosPicker(
            isPresented: $isPhotoLibraryPresented,
            selection: $selectedPhotoLibraryItem,
            matching: .images
        )
        .onChange(of: selectedPhotoLibraryItem) { _, item in
            guard let item, let request = libraryImportRequest else { return }
            Task {
                await importFromPhotoLibrary(item: item, request: request)
            }
        }
        .onChange(of: isPhotoLibraryPresented) { _, isPresented in
            if !isPresented, selectedPhotoLibraryItem == nil {
                libraryImportRequest = nil
            }
        }
        #endif
        .floatingChromeHidden()
    }

    private var importerAllowedTypes: [UTType] {
        if importerRequest?.includeMovies == true {
            return [.image, .movie]
        }
        return [.image]
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

    private func presentPhotoLibrary(for type: EntryType) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        libraryImportRequest = LibraryImportRequest(type: type)
        selectedPhotoLibraryItem = nil
        isPhotoLibraryPresented = true
        #else
        importerRequest = ImportRequest(type: type, includeMovies: false)
        #endif
    }

    private func presentCameraCapture(for type: EntryType) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        cameraRequest = CameraCaptureRequest(type: type)
        #else
        importerRequest = ImportRequest(type: type, includeMovies: true)
        #endif
    }

    #if os(iOS) && !targetEnvironment(macCatalyst)
    private func importFromPhotoLibrary(
        item: PhotosPickerItem,
        request: LibraryImportRequest
    ) async {
        defer {
            selectedPhotoLibraryItem = nil
            libraryImportRequest = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                viewModel.errorMessage = "The selected photo couldn't be loaded."
                return
            }

            let imageType = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })
            let fileExtension = imageType?.preferredFilenameExtension ?? "jpg"
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)

            try data.write(to: temporaryURL, options: .atomic)
            defer { try? FileManager.default.removeItem(at: temporaryURL) }

            await viewModel.importPhoto(from: temporaryURL, for: request.type)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func persist(
        draft: CapturedMediaDraft,
        request: CameraCaptureRequest
    ) async -> String? {
        switch draft {
        case .photo(let url, _, _):
            await viewModel.importPhoto(from: url, for: request.type)
        case .video(let url, _, _, _, _):
            await viewModel.importVideo(from: url, for: request.type)
        }

        return viewModel.errorMessage
    }
    #endif
}

private struct ImportRequest: Identifiable {
    let id = UUID()
    let type: EntryType
    let includeMovies: Bool
}

#if os(iOS) && !targetEnvironment(macCatalyst)
private struct CameraCaptureRequest: Identifiable {
    let id = UUID()
    let type: EntryType
}

private struct LibraryImportRequest: Identifiable {
    let id = UUID()
    let type: EntryType
}
#endif

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
