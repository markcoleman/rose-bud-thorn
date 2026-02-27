import SwiftUI
import UniformTypeIdentifiers
import CoreModels

public struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel
    @State private var importerType: EntryType?

    public init(environment: AppEnvironment, dayKey: LocalDayKey) {
        _viewModel = State(initialValue: DayDetailViewModel(environment: environment, dayKey: dayKey))
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
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
            .padding()
        }
        .navigationTitle(bindable.dayKey.isoDate)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    Task { await bindable.save() }
                }
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(bindable.isSaving)
            }
        }
        .task {
            await bindable.load()
        }
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
}
