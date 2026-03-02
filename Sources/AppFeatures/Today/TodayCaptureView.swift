import SwiftUI
import UniformTypeIdentifiers
import CoreModels
import DocumentStore
#if os(iOS) && !targetEnvironment(macCatalyst)
import PhotosUI
import MessageUI
#endif

public struct TodayCaptureView: View {
    @State private var viewModel: TodayViewModel
    @Binding private var captureLaunchRequest: CaptureLaunchRequest?
    private let refreshTrigger: Int
    @State private var importerRequest: ImportRequest?
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var cameraRequest: CameraCaptureRequest?
    @State private var libraryImportRequest: LibraryImportRequest?
    @State private var isPhotoLibraryPresented = false
    @State private var selectedPhotoLibraryItem: PhotosPickerItem?
    #endif
    @State private var tagsText = ""
    @State private var isPreparingDayShare = false
    @State private var sharePayload: DayShareCardPayload?
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var isMessageComposerPresented = false
    @State private var isActivitySharePresented = false
    #endif
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(
        environment: AppEnvironment,
        captureLaunchRequest: Binding<CaptureLaunchRequest?> = .constant(nil),
        refreshTrigger: Int = 0
    ) {
        _viewModel = State(initialValue: TodayViewModel(environment: environment))
        _captureLaunchRequest = captureLaunchRequest
        self.refreshTrigger = refreshTrigger
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: dynamicTypeSize.isAccessibilitySize ? 18 : 14) {
                        header(bindable)

                        engagementHub(bindable)

                        if bindable.completionSummary.last7DaysCompleted.count == 7 {
                            streakCard(summary: bindable.completionSummary)
                        }

                        ForEach(EntryType.allCases, id: \.self) { type in
                            EntryRowCard(
                                type: type,
                                shortText: bindable.bindingText(for: type),
                                journalText: bindable.bindingJournal(for: type),
                                promptSelection: bindable.prompt(for: type),
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
            .background(
                Group {
                    if bindable.os26UIEnabled {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(DesignTokens.backgroundGradient.opacity(0.92))
                    } else {
                        DesignTokens.backgroundGradient
                    }
                }
                .ignoresSafeArea()
            )
            .navigationTitle("Today")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItemGroup(placement: toolbarPlacement) {
                    if bindable.isDayShareFeatureEnabled {
                        Button {
                            Task {
                                await beginDayShare(model: bindable, markNudgeHandled: true)
                            }
                        } label: {
                            if isPreparingDayShare {
                                ProgressView()
                            } else {
                                Label("Share", systemImage: "message.fill")
                            }
                        }
                        .disabled(!bindable.isDayShareReady || isPreparingDayShare)
                        .help(bindable.isDayShareReady ? "Share your day in Messages." : (bindable.dayShareDisabledReason ?? "Day sharing is unavailable."))
                    }

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
            .onChange(of: refreshTrigger) { _, _ in
                Task {
                    await bindable.load()
                    tagsText = bindable.entry.tags.joined(separator: ", ")
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { bindable.shouldPresentShareNudge },
                    set: { isPresented in
                        if !isPresented {
                            bindable.dismissShareNudge()
                        }
                    }
                )
            ) {
                daySharePromptSheet(bindable)
                    .presentationDetents([.medium])
            }
            #if os(iOS) && !targetEnvironment(macCatalyst)
            .sheet(isPresented: $isMessageComposerPresented, onDismiss: {
                clearSharePayload(bindable)
            }) {
                if let payload = sharePayload {
                    MessageComposerView(
                        bodyText: payload.messageBody,
                        attachmentURL: payload.outputURL,
                        attachmentTypeIdentifier: payload.outputTypeIdentifier
                    ) { result in
                        switch result {
                        case .sent:
                            Task { await bindable.recordDayShareSent() }
                        case .failed:
                            Task { await bindable.recordDayShareFailed() }
                        case .cancelled:
                            break
                        }
                        isMessageComposerPresented = false
                    }
                    .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $isActivitySharePresented, onDismiss: {
                clearSharePayload(bindable)
            }) {
                if let payload = sharePayload {
                    ActivityShareSheetView(
                        activityItems: [payload.outputURL, payload.messageBody]
                    ) { completed in
                        if completed {
                            Task { await bindable.recordDayShareSent() }
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            #else
            .sheet(item: $sharePayload, onDismiss: {
                clearSharePayload(bindable)
            }) { payload in
                NavigationStack {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share your card")
                            .font(.headline)
                        Text(payload.messageBody)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ShareLink(item: payload.outputURL) {
                            Label("Share Card", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Share Day")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                sharePayload = nil
                            }
                        }
                    }
                }
            }
            #endif
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

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .topBarTrailing
        #endif
    }

    private func header(_ model: TodayViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandMarkView()
            Text(Date.now.formatted(date: .complete, time: .omitted))
                .foregroundStyle(.secondary)
                .accessibilityLabel("Today, \(Date.now.formatted(date: .complete, time: .omitted))")

            if model.isDayShareFeatureEnabled, let reason = model.dayShareDisabledReason {
                Text(reason)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
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

    @ViewBuilder
    private func engagementHub(_ model: TodayViewModel) -> some View {
        EngagementHubView(
            insightCards: model.insightCards,
            resurfacedMemories: model.resurfacedMemories,
            onTapInsightCard: { _ in
                Task { await model.recordInsightTap() }
            },
            onSnoozeMemory: { memory in
                Task { await model.snoozeMemory(memory) }
            },
            onDismissMemory: { memory in
                Task { await model.dismissMemory(memory) }
            },
            onThenVsNow: { memory in
                model.applyThenVsNowPrompt(for: memory)
            }
        )
    }

    private func streakCard(summary: EntryCompletionSummary) -> some View {
        HStack(spacing: 14) {
            WeeklyCompletionRing(progress: summary.last7DaysCompleted.filter(\.self).count, total: 7)

            VStack(alignment: .leading, spacing: 6) {
                Text(streakTitle(summary))
                    .font(.headline)
                Text(streakMessage(summary))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(DesignTokens.surfaceElevated))
    }

    private func streakTitle(_ summary: EntryCompletionSummary) -> String {
        if summary.isTodayComplete, summary.streakCount <= 1 {
            return "New streak started"
        }

        if summary.isTodayComplete, summary.streakCount > 1 {
            return "\(summary.streakCount)-day streak"
        }

        if summary.previousStreakCount > 0 {
            return "A fresh start today"
        }

        return "Build your reflection streak"
    }

    private func streakMessage(_ summary: EntryCompletionSummary) -> String {
        if summary.isTodayComplete {
            return "Great follow-through. Your weekly ring updates instantly as you reflect."
        }

        if summary.previousStreakCount > 0 {
            return "You made progress for \(summary.previousStreakCount) days. Add one entry today to restart."
        }

        return "Capture one Rose, Bud, or Thorn to fill today on your 7-day ring."
    }

    private func daySharePromptSheet(_ model: TodayViewModel) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Day Complete")
                    .font(.title3.weight(.semibold))
                Text("Send your Rose, Bud, Thorn card in Messages.")
                    .foregroundStyle(.secondary)

                Button {
                    model.markShareNudgeHandled()
                    Task {
                        await beginDayShare(model: model, markNudgeHandled: false)
                    }
                } label: {
                    Label("Send in Messages", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.isDayShareReady || isPreparingDayShare)

                Button("Not Now") {
                    model.dismissShareNudge()
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle("Share")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        model.dismissShareNudge()
                    }
                }
            }
        }
    }

    private func beginDayShare(model: TodayViewModel, markNudgeHandled: Bool) async {
        guard model.isDayShareReady else { return }

        if markNudgeHandled {
            model.markShareNudgeHandled()
        }

        isPreparingDayShare = true
        defer { isPreparingDayShare = false }

        do {
            let payload = try await model.makeDaySharePayload()
            sharePayload = payload
            presentPreparedSharePayload()
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    private func clearSharePayload(_ model: TodayViewModel) {
        guard let payload = sharePayload else { return }
        sharePayload = nil
        Task {
            await model.disposeDaySharePayload(payload)
        }
    }

    private func presentPreparedSharePayload() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments() {
            isMessageComposerPresented = true
            return
        }
        isActivitySharePresented = true
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

    private func consumeLaunchRequestIfNeeded(_ model: TodayViewModel) {
        guard let request = captureLaunchRequest else { return }
        presentCapture(for: request.type, dayKey: model.dayKey)
        captureLaunchRequest = nil
    }

    private func presentCapture(for type: EntryType, dayKey: LocalDayKey) {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        cameraRequest = CameraCaptureRequest(type: type, dayKey: dayKey)
        #else
        importerRequest = ImportRequest(type: type, dayKey: dayKey, includeMovies: true)
        #endif
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
        model: TodayViewModel
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
                try await model.importPhotoNow(from: temporaryURL, for: request.type, targetDay: request.dayKey)
            case .mismatched(let actual):
                model.errorMessage = "Only photos captured on \(request.dayKey.isoDate) are allowed. This photo appears from \(actual.isoDate)."
            case .missingTimestamp:
                model.errorMessage = "This photo is missing a capture timestamp and can't be attached to today's entry."
            }
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }
    #endif

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




private struct WeeklyCompletionRing: View {
    let progress: Int
    let total: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignTokens.surface, lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(progress) / CGFloat(max(total, 1)))
                .stroke(DesignTokens.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(progress)/\(total)")
                    .font(.caption.weight(.semibold))
                Text("week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
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
