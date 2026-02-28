import SwiftUI
import CoreModels

public struct WeeklyReviewFlowView: View {
    @State private var viewModel: WeeklyReviewViewModel
    @State private var step: Step = .questions
    @Environment(\.dismiss) private var dismiss

    public let onSummaryGenerated: (SummaryArtifact) -> Void

    public init(
        environment: AppEnvironment,
        onSummaryGenerated: @escaping (SummaryArtifact) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: WeeklyReviewViewModel(environment: environment))
        self.onSummaryGenerated = onSummaryGenerated
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch step {
                    case .questions:
                        questionsStep(bindable)
                    case .preview:
                        previewStep(bindable)
                    case .summary:
                        summaryStep(bindable)
                    }

                    if let error = bindable.errorMessage {
                        ErrorBanner(message: error) {
                            bindable.errorMessage = nil
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Weekly Review")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await bindable.load()
            }
        }
    }

    @ViewBuilder
    private func questionsStep(_ model: WeeklyReviewViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Week \(model.weekKey)")
                .font(.headline)

            if let previous = model.previousWeekIntention {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Last week's intention")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(previous.text)
                        .font(.body)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(DesignTokens.surfaceElevated))
            }

            Text("Guided check-in")
                .font(.title3.weight(.semibold))

            ForEach(model.questions) { question in
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.text)
                        .font(.subheadline.weight(.semibold))

                    TextField(
                        "Optional",
                        text: Binding(
                            get: { model.responses[question.id, default: ""] },
                            set: { model.responses[question.id] = $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Intention for next week")
                    .font(.subheadline.weight(.semibold))
                TextField(
                    "Optional",
                    text: Binding(
                        get: { model.intentionText },
                        set: { model.intentionText = $0 }
                    ),
                    axis: .vertical
                )
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 10) {
                Button("Skip to Summary") {
                    Task { await generateAndAdvance(model) }
                }
                .buttonStyle(.bordered)

                Button("Preview Highlights") {
                    step = .preview
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private func previewStep(_ model: WeeklyReviewViewModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Preview highlights")
                .font(.title3.weight(.semibold))

            ForEach(model.previewHighlights, id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)
                        .padding(.top, 4)
                    Text(line)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 10) {
                Button("Back") {
                    step = .questions
                }
                .buttonStyle(.bordered)

                Button("Generate Summary") {
                    Task { await generateAndAdvance(model) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private func summaryStep(_ model: WeeklyReviewViewModel) -> some View {
        if let artifact = model.generatedArtifact {
            SummaryDetailView(
                artifact: artifact,
                markdownURL: model.environment.summaryMarkdownURL(period: .week, key: artifact.key),
                regenerate: {
                    Task { await generateAndAdvance(model) }
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ContentUnavailableView(
                "Summary Unavailable",
                systemImage: "doc.text",
                description: Text("Generate a weekly summary to finish this review.")
            )
        }
    }

    private func generateAndAdvance(_ model: WeeklyReviewViewModel) async {
        guard !model.isGenerating else { return }
        if let artifact = await model.generateSummary() {
            onSummaryGenerated(artifact)
            step = .summary
        }
    }

    private enum Step {
        case questions
        case preview
        case summary
    }
}
