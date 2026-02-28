import SwiftUI
import UniformTypeIdentifiers
import CoreModels

public struct TodayCaptureView: View {
    @State private var viewModel: TodayViewModel
    @State private var importerType: EntryType?
    @State private var tagsText = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(environment: AppEnvironment) {
        _viewModel = State(initialValue: TodayViewModel(environment: environment))
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
                                isExpanded: bindable.isExpanded(type),
                                onShortTextChange: { bindable.updateShortText($0, for: type) },
                                onJournalTextChange: { bindable.updateJournalText($0, for: type) },
                                onToggleExpanded: { bindable.toggleExpanded(type) },
                                onAddPhoto: { importerType = type },
                                onRemovePhoto: { photo in
                                    Task { await bindable.removePhoto(photo, for: type) }
                                },
                                photoURL: { bindable.photoURL(for: $0) }
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
                    .padding(.vertical, 16)
                }
            }
            .background(DesignTokens.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Today")
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
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { importerType != nil },
                set: { isPresented in if !isPresented { importerType = nil } }
            ),
            allowedContentTypes: [.image]
        ) { result in
            guard let type = importerType else { return }
            switch result {
            case .success(let url):
                Task { await bindable.importPhoto(from: url, for: type) }
            case .failure(let error):
                bindable.errorMessage = error.localizedDescription
            }
            importerType = nil
        }
    }

    private var toolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .topBarTrailing
        #endif
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
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
}
