import SwiftUI
import CoreModels

public struct SummaryListView: View {
    @State private var viewModel: SummaryViewModel
    @Binding private var summaryLaunchRequest: SummaryLaunchRequest?
    @State private var isWeeklyReviewPresented = false
    @State private var compactNavigationPath: [SummaryCompactRoute] = []
    @State private var selectedMemoryDay: LocalDayKey?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    public init(
        environment: AppEnvironment,
        summaryLaunchRequest: Binding<SummaryLaunchRequest?> = .constant(nil)
    ) {
        _viewModel = State(initialValue: SummaryViewModel(environment: environment))
        _summaryLaunchRequest = summaryLaunchRequest
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        Group {
            if horizontalSizeClass == .compact {
                NavigationStack(path: $compactNavigationPath) {
                    compactSummaryList(bindable)
                        .navigationTitle("Summaries")
                        #if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        #endif
                        .navigationDestination(for: SummaryCompactRoute.self) { route in
                            switch route {
                            case .artifact(let key):
                                if let artifact = bindable.artifacts.first(where: { $0.key == key }) {
                                    summaryDetail(artifact, model: bindable)
                                } else {
                                    ContentUnavailableView(
                                        "No Summary",
                                        systemImage: "doc.text",
                                        description: Text("Generate a summary to get started.")
                                    )
                                }
                            case .day(let dayKey):
                                DayDetailView(environment: bindable.environment, dayKey: dayKey)
                            }
                        }
                }
            } else {
                NavigationSplitView {
                    regularSummaryList(bindable)
                        .navigationTitle("Summaries")
                } detail: {
                    splitDetail(bindable)
                }
            }
        }
        .background(
            Group {
                if bindable.os26UIEnabled {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(DesignTokens.backgroundGradient.opacity(0.9))
                } else {
                    DesignTokens.backgroundGradient
                }
            }
            .ignoresSafeArea()
        )
        .sheet(isPresented: $isWeeklyReviewPresented) {
            WeeklyReviewFlowView(environment: bindable.environment) { artifact in
                Task { await handleGeneratedArtifact(artifact, model: bindable) }
            }
        }
        .task(id: bindable.selectedPeriod) {
            await bindable.loadList()
        }
        .task {
            consumeLaunchRequestIfNeeded(bindable)
        }
        .onChange(of: summaryLaunchRequest?.id) { _, _ in
            consumeLaunchRequestIfNeeded(bindable)
        }
    }

    @ViewBuilder
    private func splitDetail(_ model: SummaryViewModel) -> some View {
        if let selectedMemoryDay {
            DayDetailView(environment: model.environment, dayKey: selectedMemoryDay)
        } else if let selected = model.selectedArtifact {
            summaryDetail(selected, model: model)
        } else {
            ContentUnavailableView("No Summary", systemImage: "doc.text", description: Text("Generate a summary to get started."))
        }
    }

    @ViewBuilder
    private func summaryDetail(_ artifact: SummaryArtifact, model: SummaryViewModel) -> some View {
        SummaryDetailView(
            artifact: artifact,
            markdownURL: model.markdownURL(for: artifact),
            regenerate: {
                Task { await model.regenerate(artifact) }
            },
            onPreviewShare: {
                Task { await model.environment.analyticsStore.record(.summaryExportPreviewed) }
            },
            onConfirmShare: {
                Task { await model.environment.analyticsStore.record(.summaryExportConfirmed) }
            }
        )
    }

    @ViewBuilder
    private func regularSummaryList(_ model: SummaryViewModel) -> some View {
        VStack(spacing: 10) {
            summaryControls(model)

            List(model.artifacts, id: \.key, selection: Binding(
                get: { model.selectedArtifact?.key },
                set: { newValue in
                    model.selectedArtifact = model.artifacts.first(where: { $0.key == newValue })
                    selectedMemoryDay = nil
                }
            )) { artifact in
                artifactRow(artifact)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        model.selectedArtifact = artifact
                        selectedMemoryDay = nil
                    }
            }
        }
    }

    @ViewBuilder
    private func compactSummaryList(_ model: SummaryViewModel) -> some View {
        VStack(spacing: 10) {
            summaryControls(model)

            List(model.artifacts, id: \.key) { artifact in
                NavigationLink(value: SummaryCompactRoute.artifact(artifact.key)) {
                    artifactRow(artifact)
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private func summaryControls(_ model: SummaryViewModel) -> some View {
        engagementHub(model)

        Picker("Period", selection: Binding(
            get: { model.selectedPeriod },
            set: {
                model.selectedPeriod = $0
                selectedMemoryDay = nil
            }
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

        if model.selectedPeriod == .week {
            Button {
                isWeeklyReviewPresented = true
            } label: {
                Label("Start Weekly Review", systemImage: "checklist")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)
        }

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
        let title = PresentationFormatting.summaryTitle(for: artifact)
        let range = PresentationFormatting.summaryRangeText(for: artifact, timeZone: .current)
        let metadata = PresentationFormatting.summaryMetadataText(for: artifact)

        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(range)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(metadata)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(range). \(metadata).")
        .accessibilityHint("Opens the selected summary.")
        .padding(.vertical, modelVerticalPadding)
    }

    @ViewBuilder
    private func engagementHub(_ model: SummaryViewModel) -> some View {
        EngagementHubView(
            insightCards: model.insightCards,
            resurfacedMemories: model.resurfacedMemories,
            onTapInsightCard: { _ in
                Task { await model.recordInsightTap() }
            },
            onOpenMemoryDay: { memory in
                openMemoryDay(memory, model: model)
            },
            onSnoozeMemory: { memory in
                Task { await model.snoozeMemory(memory) }
            },
            onDismissMemory: { memory in
                Task { await model.dismissMemory(memory) }
            },
            onThenVsNow: { _ in
                openURL(URL(string: "rosebudthorn://today?source=summaries&focus=resurfacing")!)
            }
        )
        .padding(.horizontal)
    }

    private var modelVerticalPadding: CGFloat {
        horizontalSizeClass == .compact ? 2 : 4
    }

    private func openMemoryDay(_ memory: ResurfacedMemory, model: SummaryViewModel) {
        selectedMemoryDay = memory.sourceDayKey

        if horizontalSizeClass == .compact {
            compactNavigationPath.append(.day(memory.sourceDayKey))
        }

        Task {
            await model.environment.analyticsStore.record(.summaryDayDetailsOpened)
        }
    }

    private func consumeLaunchRequestIfNeeded(_ model: SummaryViewModel) {
        guard let request = summaryLaunchRequest else { return }
        summaryLaunchRequest = nil

        Task {
            await handleLaunchRequest(request, model: model)
        }
    }

    private func handleLaunchRequest(_ request: SummaryLaunchRequest, model: SummaryViewModel) async {
        switch request.action {
        case .openCurrentWeeklySummary:
            model.selectedPeriod = .week
            selectedMemoryDay = nil
            await model.loadList()

            let currentKey = model.environment.periodCalculator.key(for: .now, period: .week, timeZone: .current)
            if let existing = model.artifacts.first(where: { $0.key == currentKey }) {
                model.selectedArtifact = existing
                showArtifactIfCompact(key: existing.key)
            } else {
                await model.generateCurrent()
                if let generated = model.selectedArtifact {
                    showArtifactIfCompact(key: generated.key)
                }
            }
        case .startWeeklyReview:
            model.selectedPeriod = .week
            selectedMemoryDay = nil
            isWeeklyReviewPresented = true
        }
    }

    private func handleGeneratedArtifact(_ artifact: SummaryArtifact, model: SummaryViewModel) async {
        selectedMemoryDay = nil
        model.selectedPeriod = artifact.period
        model.selectedArtifact = artifact
        await model.loadList()
    }

    private func showArtifactIfCompact(key: String) {
        guard horizontalSizeClass == .compact else { return }
        compactNavigationPath = [.artifact(key)]
    }
}

private enum SummaryCompactRoute: Hashable {
    case artifact(String)
    case day(LocalDayKey)
}
