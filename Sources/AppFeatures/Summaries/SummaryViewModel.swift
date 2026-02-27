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

    public let environment: AppEnvironment

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public func loadList() async {
        do {
            artifacts = try await environment.summaryService.list(period: selectedPeriod)
            if selectedArtifact == nil {
                selectedArtifact = artifacts.first
            }
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
}
