import SwiftUI
import CoreModels

public struct SummaryListView: View {
    @State private var viewModel: SummaryViewModel

    public init(environment: AppEnvironment) {
        _viewModel = State(initialValue: SummaryViewModel(environment: environment))
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        NavigationSplitView {
            VStack(spacing: 10) {
                Picker("Period", selection: $bindable.selectedPeriod) {
                    ForEach(SummaryPeriod.allCases, id: \.self) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Button {
                    Task { await bindable.generateCurrent() }
                } label: {
                    Label("Generate Current", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .keyboardShortcut("g", modifiers: [.command, .shift])

                List(bindable.artifacts, id: \.key, selection: Binding(
                    get: { bindable.selectedArtifact?.key },
                    set: { newValue in
                        bindable.selectedArtifact = bindable.artifacts.first(where: { $0.key == newValue })
                    }
                )) { artifact in
                    VStack(alignment: .leading) {
                        Text(artifact.key)
                        Text(artifact.generatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        bindable.selectedArtifact = artifact
                    }
                }

                if bindable.isGenerating {
                    ProgressView()
                }

                if let error = bindable.errorMessage {
                    ErrorBanner(message: error) {
                        bindable.errorMessage = nil
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Summaries")
        } detail: {
            if let selected = bindable.selectedArtifact {
                SummaryDetailView(
                    artifact: selected,
                    markdownURL: bindable.markdownURL(for: selected),
                    regenerate: {
                        Task { await bindable.regenerate(selected) }
                    }
                )
            } else {
                ContentUnavailableView("No Summary", systemImage: "doc.text", description: Text("Generate a summary to get started."))
            }
        }
        .task(id: bindable.selectedPeriod) {
            await bindable.loadList()
        }
    }
}
