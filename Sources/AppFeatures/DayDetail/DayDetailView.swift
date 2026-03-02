import SwiftUI
import UniformTypeIdentifiers
import CoreModels
#if os(iOS) && !targetEnvironment(macCatalyst)
import MessageUI
#endif

public struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel
    @State private var importerType: EntryType?
    @State private var isPreparingDayShare = false
    @State private var sharePayload: DayShareCardPayload?
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var isMessageComposerPresented = false
    @State private var isActivitySharePresented = false
    #endif

    public init(environment: AppEnvironment, dayKey: LocalDayKey) {
        _viewModel = State(initialValue: DayDetailViewModel(environment: environment, dayKey: dayKey))
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if bindable.isDayShareFeatureEnabled, let reason = bindable.dayShareDisabledReason {
                        Text(reason)
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    }

                    ForEach(EntryType.allCases, id: \.self) { type in
                        EntryItemEditorView(
                            type: type,
                            shortText: bindable.entry.item(for: type).shortText,
                            journalText: bindable.entry.item(for: type).journalTextMarkdown,
                            photos: bindable.entry.item(for: type).photos,
                            onShortText: { bindable.updateShortText($0, for: type) },
                            onJournal: { bindable.updateJournal($0, for: type) },
                            onAddPhoto: { importerType = type },
                            onRemovePhoto: { ref in
                                Task { await bindable.removePhoto(ref, for: type) }
                            },
                            photoURL: { bindable.photoURL(for: $0) }
                        )
                    }

                    if let error = bindable.errorMessage {
                        ErrorBanner(message: error) {
                            bindable.errorMessage = nil
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignTokens.contentHorizontalPadding(for: geometry.size.width))
                .padding(.vertical, 14)
            }
        }
        .navigationTitle(PresentationFormatting.localizedDayTitle(for: bindable.dayKey))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if bindable.isDayShareFeatureEnabled {
                    Button {
                        Task {
                            await beginDayShare(model: bindable)
                        }
                    } label: {
                        if isPreparingDayShare {
                            ProgressView()
                        } else {
                            Label("Share", systemImage: AppIcon.shareMessage.systemName)
                        }
                    }
                    .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                    .disabled(!bindable.isDayShareReady || isPreparingDayShare)
                    .help(bindable.isDayShareReady ? "Share this day in Messages." : (bindable.dayShareDisabledReason ?? "Day sharing is unavailable."))
                }

                Button("Save") {
                    Task { await bindable.save() }
                }
                .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(bindable.isSaving)
            }
        }
        .task {
            await bindable.load()
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
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    ShareLink(item: payload.outputURL) {
                        Label("Share Card", systemImage: AppIcon.shareExport.systemName)
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
        .fileImporter(
            isPresented: Binding(
                get: { importerType != nil },
                set: { isPresented in if !isPresented { importerType = nil } }
            ),
            allowedContentTypes: [.image]
        ) { result in
            guard let type = importerType else { return }
            if case .success(let url) = result {
                Task { await bindable.importPhoto(from: url, for: type) }
            }
            if case .failure(let error) = result {
                bindable.errorMessage = error.localizedDescription
            }
            importerType = nil
        }
    }

    private func beginDayShare(model: DayDetailViewModel) async {
        guard model.isDayShareReady else { return }

        isPreparingDayShare = true
        defer { isPreparingDayShare = false }

        await model.prepareShareSaveIfNeeded()
        if model.errorMessage != nil {
            return
        }

        do {
            let payload = try await model.makeDaySharePayload()
            sharePayload = payload
            presentPreparedSharePayload()
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    private func clearSharePayload(_ model: DayDetailViewModel) {
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
}
