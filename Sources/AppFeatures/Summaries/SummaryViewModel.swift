import Foundation
import Observation
import CoreModels

@MainActor
@Observable
public final class SummaryViewModel {
    public var selectedPeriod: SummaryPeriod = .week
    public var artifacts: [SummaryArtifact] = []
    public var selectedArtifact: SummaryArtifact?
    public var isGenerating = false
    public var errorMessage: String?
    public var insightCards: [InsightCard] = []
    public var resurfacedMemories: [ResurfacedMemory] = []
    public var os26UIEnabled = true

    public let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public func loadList() async {
        do {
            os26UIEnabled = featureFlags.os26UIEnabled
            artifacts = try await environment.summaryService.list(period: selectedPeriod)
            if selectedArtifact == nil {
                selectedArtifact = artifacts.first
            }
            try await loadEngagementHub()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func generateCurrent() async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            let key = environment.periodCalculator.key(for: .now, period: selectedPeriod)
            let artifact = try await environment.summaryService.generate(period: selectedPeriod, key: key)
            selectedArtifact = artifact
            await loadList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func regenerate(_ artifact: SummaryArtifact) async {
        isGenerating = true
        defer { isGenerating = false }

        do {
            selectedArtifact = try await environment.summaryService.generate(period: artifact.period, key: artifact.key)
            await loadList()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func markdownURL(for artifact: SummaryArtifact) -> URL {
        environment.summaryMarkdownURL(period: artifact.period, key: artifact.key)
    }

    public func dismissMemory(_ memory: ResurfacedMemory) async {
        await handleMemoryDecision(memory, action: .dismiss)
    }

    public func snoozeMemory(_ memory: ResurfacedMemory) async {
        await handleMemoryDecision(memory, action: .snooze)
    }

    public func recordInsightTap() async {
        await environment.analyticsStore.record(.insightCardTapped)
    }

    private func loadEngagementHub() async throws {
        if featureFlags.insightsEnabled {
            insightCards = try await environment.insightEngine.cards(for: .now, timeZone: .current)
        } else {
            insightCards = []
        }

        if featureFlags.resurfacingEnabled {
            resurfacedMemories = try await environment.memoryResurfacingService.memories(for: .now, timeZone: .current)
        } else {
            resurfacedMemories = []
        }
    }

    private func handleMemoryDecision(_ memory: ResurfacedMemory, action: ResurfacingAction) async {
        do {
            _ = try await environment.memoryResurfacingService.record(
                decisionAction: action,
                for: memory,
                referenceDate: .now,
                timeZone: .current
            )
            resurfacedMemories.removeAll { $0.id == memory.id }
            await environment.analyticsStore.record(.resurfacingActioned)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var featureFlags: AppFeatureFlags {
        environment.featureFlagStore.load(defaults: environment.featureFlags)
    }
}
