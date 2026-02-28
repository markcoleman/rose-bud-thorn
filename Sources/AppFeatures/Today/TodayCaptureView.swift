import SwiftUI
import UniformTypeIdentifiers
import CoreModels

public struct TodayCaptureView: View {
    @State private var viewModel: TodayViewModel
    @Binding private var captureLaunchRequest: CaptureLaunchRequest?
    @State private var importerRequest: ImportRequest?
    #if os(iOS)
    @State private var cameraRequest: CameraCaptureRequest?
    #endif
    @State private var tagsText = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        environment: AppEnvironment,
        captureLaunchRequest: Binding<CaptureLaunchRequest?> = .constant(nil)
    ) {
        _viewModel = State(initialValue: TodayViewModel(environment: environment))
        _captureLaunchRequest = captureLaunchRequest
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 18 : 14) {
                        header

                        ForEach(EntryType.allCases, id: \.self) { type in
                            EntryRowCard(
                                type: type,
                                shortText: bindable.bindingText(for: type),
                                journalText: bindable.bindingJournal(for: type),
                                photos: bindable.photos(for: type),
                                videos: bindable.videos(for: type),
                                isExpanded: bindable.isExpanded(type),
                                onShortTextChange: { bindable.updateShortText($0, for: type) },
                                onJournalTextChange: { bindable.updateJournalText($0, for: type) },
                                onToggleExpanded: { bindable.toggleExpanded(type) },
                                onAddCapture: {
                                    presentCapture(for: type, dayKey: bindable.dayKey)
                                },
                                onRemovePhoto: { photo in
                                    Task { await bindable.removePhoto(photo, for: type) }
                                },
                                onRemoveVideo: { video in
                                    Task { await bindable.removeVideo(video, for: type) }
                                },
                                photoURL: { bindable.photoURL(for: $0) },
                                videoURL: { bindable.videoURL(for: $0) }
                            )
                        }

                        metadata(bindable)

                        if let errorMessage = bindable.errorMessage {
                            ErrorBanner(message: errorMessage) {
                                bindable.errorMessage = nil
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: geometry.size.height, alignment: .topLeading)
                    .padding(.horizontal, DesignTokens.contentHorizontalPadding(for: geometry.size.width))
                    .padding(.top, DesignTokens.contentTopPadding(for: geometry.size.width))
                    .padding(.bottom, DesignTokens.contentBottomPadding(for: geometry.size.width))
                }
            }
            .background(DesignTokens.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Today")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: toolbarPlacement) {
                    if bindable.isSaving {
                        ProgressView()
                    } else if let lastSaved = bindable.lastSavedAt {
                        Text(lastSaved.formatted(date: .omitted, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                await bindable.load()
                tagsText = bindable.entry.tags.joined(separator: ", ")
                consumeLaunchRequestIfNeeded(bindable)
            }
            .onChange(of: captureLaunchRequest?.id) { _, _ in
                consumeLaunchRequestIfNeeded(bindable)
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { importerRequest != nil },
                set: { isPresented in if !isPresented { importerRequest = nil } }
            ),
            allowedContentTypes: importerAllowedTypes
        ) { result in
            guard let request = importerRequest else { return }
            switch result {
            case .success(let url):
                Task {
                    do {
                        if isMovieURL(url) {
                            try await bindable.importVideoNow(from: url, for: request.type, targetDay: request.dayKey)
                        } else {
                            try await bindable.importPhotoNow(from: url, for: request.type, targetDay: request.dayKey)
                        }
                    } catch {
                        bindable.errorMessage = error.localizedDescription
                    }
                }
            case .failure(let error):
                bindable.errorMessage = error.localizedDescription
            }
            importerRequest = nil
        }
        #if os(iOS)
        .fullScreenCover(item: $cameraRequest) { request in
            MomentCameraView(
                entryType: request.type,
                onFallbackImport: {
                    importerRequest = ImportRequest(type: request.type, dayKey: request.dayKey, includeMovies: true)
                },
                onConfirm: { draft in
                    await persist(draft: draft, request: request, model: bindable)
                }
            )
        }
        #endif
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .topBarTrailing
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandMarkView()
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Today, \(Date.now.formatted(date: .complete, time: .omitted))")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadata(_ model: TodayViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Tags (comma separated)", text: $tagsText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.surface)
                )
                .onSubmit {
                    model.setTags(from: tagsText)
                }

            ViewThatFits {
                HStack(spacing: 12) {
                Picker("Mood", selection: Binding(
                    get: { model.entry.mood ?? 0 },
                    set: { newValue in model.setMood(newValue == 0 ? nil : newValue) }
                )) {
                    Text("Mood").tag(0)
                    ForEach(1...5, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    model.toggleFavorite()
                } label: {
                    Label("Favorite", systemImage: model.entry.favorite ? "star.fill" : "star")
                }
                .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Picker("Mood", selection: Binding(
                        get: { model.entry.mood ?? 0 },
                        set: { newValue in model.setMood(newValue == 0 ? nil : newValue) }
                    )) {
                        Text("Mood").tag(0)
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button {
                        model.toggleFavorite()
                    } label: {
                        Label("Favorite", systemImage: model.entry.favorite ? "star.fill" : "star")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(DesignTokens.surfaceElevated))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var importerAllowedTypes: [UTType] {
        if importerRequest?.includeMovies == true {
            return [.image, .movie]
        }
        return [.image]
    }

    private func isMovieURL(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else {
            return false
        }
        return type.conforms(to: .movie)
    }

    private func consumeLaunchRequestIfNeeded(_ model: TodayViewModel) {
        guard let request = captureLaunchRequest else { return }
        presentCapture(for: request.type, dayKey: model.dayKey)
        captureLaunchRequest = nil
    }

    private func presentCapture(for type: EntryType, dayKey: LocalDayKey) {
        #if os(iOS)
        cameraRequest = CameraCaptureRequest(type: type, dayKey: dayKey)
        #else
        importerRequest = ImportRequest(type: type, dayKey: dayKey, includeMovies: true)
        #endif
    }

    private func persist(
        draft: CapturedMediaDraft,
        request: CameraCaptureRequest,
        model: TodayViewModel
    ) async -> String? {
        do {
            switch draft {
            case .photo(let url, _, _):
                try await model.importPhotoNow(from: url, for: request.type, targetDay: request.dayKey)
            case .video(let url, _, _, _, _):
                try await model.importVideoNow(from: url, for: request.type, targetDay: request.dayKey)
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

private struct ImportRequest: Identifiable {
    let id = UUID()
    let type: EntryType
    let dayKey: LocalDayKey
    let includeMovies: Bool
}

private struct CameraCaptureRequest: Identifiable {
    let id = UUID()
    let type: EntryType
    let dayKey: LocalDayKey
}
