import SwiftUI
import UniformTypeIdentifiers
import CoreModels
import DocumentStore
#if os(iOS)
import UIKit
#endif
#if os(iOS) && !targetEnvironment(macCatalyst)
import PhotosUI
#endif

public struct JournalView: View {
    @State private var viewModel: JournalViewModel
    @Binding private var captureLaunchRequest: CaptureLaunchRequest?
    private let refreshTrigger: Int

    @State private var importerRequest: ImportRequest?
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var cameraRequest: CameraCaptureRequest?
    @State private var libraryImportRequest: LibraryImportRequest?
    @State private var isPhotoLibraryPresented = false
    @State private var selectedPhotoLibraryItem: PhotosPickerItem?
    #endif

    @State private var navigationSelection: JournalNavigationSelection?
    @State private var showJumpToToday = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let scrollTopID = "journal-scroll-top"
    private let scrollCoordinateSpace = "journal-scroll"

    public init(
        environment: AppEnvironment,
        captureLaunchRequest: Binding<CaptureLaunchRequest?> = .constant(nil),
        refreshTrigger: Int = 0
    ) {
        _viewModel = State(initialValue: JournalViewModel(environment: environment))
        _captureLaunchRequest = captureLaunchRequest
        self.refreshTrigger = refreshTrigger
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        topAnchorMarker

                        JournalTodayCardView(
                            entry: bindable.todayEntry,
                            saveFeedbackState: bindable.todaySaveFeedbackState,
                            onShortTextChange: { type, text in
                                bindable.updateTodayShortText(text, for: type)
                            },
                            onJournalTextChange: { type, text in
                                bindable.updateTodayJournalText(text, for: type)
                            },
                            onOpenPhotoLibrary: { type in
                                presentCapture(for: type, dayKey: bindable.todayDayKey)
                            },
                            onOpenCamera: { type in
                                presentCameraCapture(for: type, dayKey: bindable.todayDayKey)
                            },
                            onRemovePhoto: { type, ref in
                                Task {
                                    await bindable.removeTodayPhoto(ref, for: type)
                                }
                            },
                            onRemoveVideo: { type, ref in
                                Task {
                                    await bindable.removeTodayVideo(ref, for: type)
                                }
                            },
                            onOpenCompletedDay: {
                                navigationSelection = JournalNavigationSelection(dayKey: bindable.todayDayKey)
                            },
                            photoURL: { ref in
                                bindable.photoURL(for: ref, day: bindable.todayDayKey)
                            },
                            videoURL: { ref in
                                bindable.videoURL(for: ref, day: bindable.todayDayKey)
                            }
                        )
                        .id(scrollTopID)

                        if !bindable.timelineDays.isEmpty {
                            Text("Memories")
                                .font(.headline)
                                .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                                .padding(.top, 2)
                        }

                        ForEach(bindable.timelineDays) { summary in
                            JournalDayCardView(
                                summary: summary,
                                mode: .timeline,
                                queryText: "",
                                category: .all,
                                photoURL: { ref in
                                    bindable.photoURL(for: ref, day: summary.dayKey)
                                },
                                onOpen: {
                                    navigationSelection = JournalNavigationSelection(dayKey: summary.dayKey)
                                }
                            )
                            .onAppear {
                                Task {
                                    await bindable.loadMoreIfNeeded(currentDayKey: summary.dayKey)
                                }
                            }
                        }

                        if bindable.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }

                        if let error = bindable.errorMessage {
                            ErrorBanner(message: error) {
                                bindable.errorMessage = nil
                            }
                        }
                    }
                    .padding(.horizontal, horizontalContentPadding)
                    .padding(.top, 0)
                    .padding(.bottom, 10)
                }
                .coordinateSpace(name: scrollCoordinateSpace)
                .scrollDismissesKeyboard(.interactively)
                .background(DesignTokens.backgroundGradient.ignoresSafeArea())
                .onPreferenceChange(JournalTopOffsetPreferenceKey.self) { value in
                    withAnimation(MotionTokens.quick) {
                        showJumpToToday = value < -180
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if usesFloatingJumpButton && showJumpToToday {
                        jumpToTodayButton {
                            scrollToTop(proxy)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                .toolbar {
                    if !usesFloatingJumpButton && showJumpToToday {
                        ToolbarItem(placement: jumpToolbarPlacement) {
                            jumpToTodayButton {
                                scrollToTop(proxy)
                            }
                        }
                    }

                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            dismissKeyboard()
                        }
                        .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                    }
                }
            }
            #if !os(macOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .navigationDestination(item: $navigationSelection) { destination in
                DayDetailView(environment: bindable.environment, dayKey: destination.dayKey)
            }
            .task {
                await bindable.load()
                consumeLaunchRequestIfNeeded(bindable)
            }
            .onChange(of: captureLaunchRequest?.id) { _, _ in
                consumeLaunchRequestIfNeeded(bindable)
            }
            .onChange(of: refreshTrigger) { _, _ in
                Task {
                    await bindable.reloadFromExternalChange()
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
                    Task {
                        if isMovieURL(url) {
                            await bindable.importVideo(from: url, for: request.type, targetDay: request.dayKey)
                        } else {
                            await bindable.importPhoto(from: url, for: request.type, targetDay: request.dayKey)
                        }
                    }
                case .failure(let error):
                    bindable.errorMessage = error.localizedDescription
                }

                importerRequest = nil
            }
            #if os(iOS) && !targetEnvironment(macCatalyst)
            .fullScreenCover(item: $cameraRequest) { request in
                MomentCameraView(
                    entryType: request.type,
                    onFallbackImport: {
                        importerRequest = ImportRequest(type: request.type, dayKey: request.dayKey, includeMovies: true)
                    },
                    onPickFromLibrary: {
                        presentPhotoLibrary(for: request.type, dayKey: request.dayKey)
                    },
                    onConfirm: { draft in
                        await persist(draft: draft, request: request, model: bindable)
                    }
                )
            }
            .photosPicker(
                isPresented: $isPhotoLibraryPresented,
                selection: $selectedPhotoLibraryItem,
                matching: .images
            )
            .overlay(alignment: .topLeading) {
                if isPhotoLibraryPresented {
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityIdentifier("journal-photo-library-presented")
                }
            }
            .onChange(of: selectedPhotoLibraryItem) { _, item in
                guard let item, let request = libraryImportRequest else { return }
                Task {
                    await importFromPhotoLibrary(item: item, request: request, model: bindable)
                }
            }
            .onChange(of: isPhotoLibraryPresented) { _, isPresented in
                if !isPresented, selectedPhotoLibraryItem == nil {
                    libraryImportRequest = nil
                }
            }
            #endif
        }
    }

    private var topAnchorMarker: some View {
        Color.clear
            .frame(height: 0)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: JournalTopOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named(scrollCoordinateSpace)).minY
                    )
                }
            )
    }

    private func jumpToTodayButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("↑ Today", systemImage: "arrow.up")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Capsule().fill(DesignTokens.surfaceElevated))
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func scrollToTop(_ proxy: ScrollViewProxy) {
        withAnimation(MotionTokens.quick) {
            proxy.scrollTo(scrollTopID, anchor: .top)
        }
        dismissKeyboard()
    }

    private func consumeLaunchRequestIfNeeded(_ model: JournalViewModel) {
        guard let request = captureLaunchRequest else { return }
        presentCapture(for: request.type, dayKey: model.todayDayKey)
        captureLaunchRequest = nil
    }

    private func presentCapture(for type: EntryType, dayKey: LocalDayKey) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        presentPhotoLibrary(for: type, dayKey: dayKey)
        #else
        importerRequest = ImportRequest(type: type, dayKey: dayKey, includeMovies: false)
        #endif
    }

    private func presentCameraCapture(for type: EntryType, dayKey: LocalDayKey) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        cameraRequest = CameraCaptureRequest(type: type, dayKey: dayKey)
        #else
        importerRequest = ImportRequest(type: type, dayKey: dayKey, includeMovies: true)
        #endif
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

    #if os(iOS) && !targetEnvironment(macCatalyst)
    private func presentPhotoLibrary(for type: EntryType, dayKey: LocalDayKey) {
        libraryImportRequest = LibraryImportRequest(type: type, dayKey: dayKey)
        selectedPhotoLibraryItem = nil
        isPhotoLibraryPresented = true
    }

    private func importFromPhotoLibrary(
        item: PhotosPickerItem,
        request: LibraryImportRequest,
        model: JournalViewModel
    ) async {
        defer {
            selectedPhotoLibraryItem = nil
            libraryImportRequest = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                model.errorMessage = "The selected photo couldn't be loaded."
                return
            }

            let imageType = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })
            let fileExtension = imageType?.preferredFilenameExtension ?? "jpg"
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)

            try data.write(to: temporaryURL, options: .atomic)
            defer { try? FileManager.default.removeItem(at: temporaryURL) }

            switch ImageCaptureDateValidator.validateImage(at: temporaryURL, matches: request.dayKey) {
            case .matches:
                await model.importPhoto(from: temporaryURL, for: request.type, targetDay: request.dayKey)
            case .mismatched(let actual):
                model.errorMessage = "Only photos captured on \(request.dayKey.isoDate) are allowed. This photo appears from \(actual.isoDate)."
            case .missingTimestamp:
                model.errorMessage = "This photo is missing a capture timestamp and can't be attached to this day's entry."
            }
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
    #endif

    private func persist(
        draft: CapturedMediaDraft,
        request: CameraCaptureRequest,
        model: JournalViewModel
    ) async -> String? {
        switch draft {
        case .photo(let url, _, _):
            await model.importPhoto(from: url, for: request.type, targetDay: request.dayKey)
        case .video(let url, _, _, _, _):
            await model.importVideo(from: url, for: request.type, targetDay: request.dayKey)
        }

        return model.errorMessage
    }

    private var horizontalContentPadding: CGFloat {
        #if os(macOS)
        return 24
        #else
        if horizontalSizeClass == .compact {
            return 16
        }
        return 24
        #endif
    }

    private var jumpToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .topBarTrailing
        #endif
    }

    private var usesFloatingJumpButton: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact && !PlatformCapabilities.isMacCatalyst
        #else
        return false
        #endif
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

private struct JournalTopOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct JournalNavigationSelection: Hashable, Identifiable {
    let dayKey: LocalDayKey

    var id: String {
        "\(dayKey.isoDate)|\(dayKey.timeZoneID)"
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

#if os(iOS) && !targetEnvironment(macCatalyst)
private struct LibraryImportRequest: Identifiable {
    let id = UUID()
    let type: EntryType
    let dayKey: LocalDayKey
}
#endif
