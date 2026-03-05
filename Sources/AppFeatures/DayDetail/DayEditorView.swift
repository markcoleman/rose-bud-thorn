import SwiftUI
import UniformTypeIdentifiers
import CoreModels

public struct DayEditorView: View {
    @Bindable private var viewModel: DayDetailViewModel
    @State private var importerType: EntryType?

    public init(viewModel: DayDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(EntryType.allCases, id: \.self) { type in
                        EntryItemEditorView(
                            type: type,
                            shortText: viewModel.entry.item(for: type).shortText,
                            journalText: viewModel.entry.item(for: type).journalTextMarkdown,
                            photos: viewModel.entry.item(for: type).photos,
                            onShortText: { viewModel.updateShortText($0, for: type) },
                            onJournal: { viewModel.updateJournal($0, for: type) },
                            onAddPhoto: { importerType = type },
                            onRemovePhoto: { ref in
                                Task { await viewModel.removePhoto(ref, for: type) }
                            },
                            photoURL: { viewModel.photoURL(for: $0) }
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
        }
        .navigationTitle("Edit Day")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                .keyboardShortcut("s", modifiers: [.command])
                .disabled(viewModel.isSaving)
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
            allowedContentTypes: [.image]
        ) { result in
            guard let type = importerType else { return }
            if case .success(let url) = result {
                Task { await viewModel.importPhoto(from: url, for: type) }
            }
            if case .failure(let error) = result {
                viewModel.errorMessage = error.localizedDescription
            }
            importerType = nil
        }
    }
}
