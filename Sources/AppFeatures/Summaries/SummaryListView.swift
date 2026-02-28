import SwiftUI
import CoreModels

public struct SummaryListView: View {
    @State private var viewModel: SummaryViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(environment: AppEnvironment) {
        _viewModel = State(initialValue: SummaryViewModel(environment: environment))
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        Group {
            if horizontalSizeClass == .compact {
                NavigationStack {
                    compactSummaryList(bindable)
                        .navigationTitle("Summaries")
                        #if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        #endif
                        .navigationDestination(for: String.self) { key in
                            if let artifact = bindable.artifacts.first(where: { $0.key == key }) {
                                SummaryDetailView(
                                    artifact: artifact,
                                    markdownURL: bindable.markdownURL(for: artifact),
                                    regenerate: {
                                        Task { await bindable.regenerate(artifact) }
                                    }
                                )
                            } else {
                                ContentUnavailableView(
                                    "No Summary",
                                    systemImage: "doc.text",
                                    description: Text("Generate a summary to get started.")
                                )
                            }
                        }
                }
            } else {
                NavigationSplitView {
                    regularSummaryList(bindable)
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
            }
        }
        .task(id: bindable.selectedPeriod) {
            await bindable.loadList()
        }
    }

    @ViewBuilder
    private func regularSummaryList(_ model: SummaryViewModel) -> some View {
        VStack(spacing: 10) {
            summaryControls(model)

            List(model.artifacts, id: \.key, selection: Binding(
                get: { model.selectedArtifact?.key },
                set: { newValue in
                    model.selectedArtifact = model.artifacts.first(where: { $0.key == newValue })
                }
            )) { artifact in
                artifactRow(artifact)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.selectedArtifact = artifact
                    }
            }
        }
    }

    @ViewBuilder
    private func compactSummaryList(_ model: SummaryViewModel) -> some View {
        VStack(spacing: 10) {
            summaryControls(model)

            List(model.artifacts, id: \.key) { artifact in
                NavigationLink(value: artifact.key) {
                    artifactRow(artifact)
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func summaryControls(_ model: SummaryViewModel) -> some View {
        Picker("Period", selection: Binding(
            get: { model.selectedPeriod },
            set: { model.selectedPeriod = $0 }
        )) {
            ForEach(SummaryPeriod.allCases, id: \.self) { period in
                Text(period.title).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)

        Button {
            Task { await model.generateCurrent() }
        } label: {
            Label("Generate Current", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
        .keyboardShortcut("g", modifiers: [.command, .shift])

        if model.isGenerating {
            ProgressView()
        }

        if let error = model.errorMessage {
            ErrorBanner(message: error) {
                model.errorMessage = nil
            }
            .padding(.horizontal)
        }
    }

    private func artifactRow(_ artifact: SummaryArtifact) -> some View {
        VStack(alignment: .leading) {
            Text(artifact.key)
            Text(artifact.generatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
