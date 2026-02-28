import Foundation
import Observation
import CoreModels

public struct WeeklyReviewQuestion: Identifiable, Hashable, Sendable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

@MainActor
@Observable
public final class WeeklyReviewViewModel {
    public let weekKey: String
    public let environment: AppEnvironment
    public let questions: [WeeklyReviewQuestion]

    public var responses: [String: String] = [:]
    public var intentionText = ""
    public var previousWeekIntention: WeeklyIntention?
    public var previewHighlights: [String] = []
    public var generatedArtifact: SummaryArtifact?
    public var isLoading = false
    public var isGenerating = false
    public var errorMessage: String?

    public init(environment: AppEnvironment, referenceDate: Date = .now) {
        self.environment = environment
        self.weekKey = environment.periodCalculator.key(for: referenceDate, period: .week, timeZone: .current)
        self.questions = [
            WeeklyReviewQuestion(id: "energy", text: "What gave you energy this week?"),
            WeeklyReviewQuestion(id: "friction", text: "Where did friction show up the most?"),
            WeeklyReviewQuestion(id: "lesson", text: "What did you learn about yourself this week?"),
            WeeklyReviewQuestion(id: "focus", text: "What deserves your focus next week?")
        ]
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await loadPreviousWeekIntention()
            try await buildPreviewHighlights()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    public func generateSummary() async -> SummaryArtifact? {
        isGenerating = true
        defer { isGenerating = false }

        do {
            try await environment.weeklyIntentionStore.save(text: intentionText, for: weekKey)
            let artifact = try await environment.summaryService.generate(period: .week, key: weekKey)
            generatedArtifact = artifact
            return artifact
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func loadPreviousWeekIntention() async throws {
        guard let previousWeekKey = previousWeekKey() else {
            previousWeekIntention = nil
            return
        }

        previousWeekIntention = try await environment.weeklyIntentionStore.load(for: previousWeekKey)
    }

    private func buildPreviewHighlights() async throws {
        if let existing = try await environment.summaryService.load(period: .week, key: weekKey),
           !existing.highlights.isEmpty {
            previewHighlights = Array(existing.highlights.prefix(5))
            return
        }

        guard let range = environment.periodCalculator.range(for: .week, key: weekKey, timeZone: .current) else {
            previewHighlights = ["No highlights available for this week yet."]
            return
        }

        let dayKeys = try await environment.entryStore.list(range: range).sorted(by: >)
        var highlights: [String] = []

        for dayKey in dayKeys {
            let entry = try await environment.entryStore.load(day: dayKey)
            for type in EntryType.allCases {
                let text = entry.item(for: type).shortText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }
                highlights.append("\(type.title): \(text)")
                if highlights.count == 5 {
                    previewHighlights = highlights
                    return
                }
            }
        }

        previewHighlights = highlights.isEmpty ? ["No highlights available for this week yet."] : highlights
    }

    private func previousWeekKey() -> String? {
        guard let currentRange = environment.periodCalculator.range(for: .week, key: weekKey, timeZone: .current) else {
            return nil
        }

        guard let previousDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: -1, to: currentRange.start) else {
            return nil
        }

        return environment.periodCalculator.key(for: previousDate, period: .week, timeZone: .current)
    }
}
