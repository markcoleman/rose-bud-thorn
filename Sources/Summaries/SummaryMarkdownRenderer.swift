import Foundation
import CoreModels

public struct SummaryMarkdownRenderer: Sendable {
    public init() {}

    public func render(
        period: SummaryPeriod,
        key: String,
        generatedAt: Date,
        entries: [EntryDay],
        highlights: [String],
        quotes: [String],
        photoRefs: [PhotoRef]
    ) -> String {
        let roseTexts = entries.map { $0.roseItem.shortText }.filter { !$0.isEmpty }
        let budTexts = entries.map { $0.budItem.shortText }.filter { !$0.isEmpty }
        let thornTexts = entries.map { $0.thornItem.shortText }.filter { !$0.isEmpty }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let highlightLines = highlights.isEmpty ? ["- No strong recurring themes yet."] : highlights.map { "- \($0)" }
        let quoteLines = quotes.isEmpty ? ["- No notable quotes captured."] : quotes.map { "- \($0)" }
        let photoLines = photoRefs.isEmpty ? ["- No photos for this period."] : photoRefs.map { "- \($0.relativePath)" }

        return """
        # \(period.title) Summary — \(key)

        _Generated at \(formatter.string(from: generatedAt))_

        ## Highlights
        \(highlightLines.joined(separator: "\n"))

        ## Rose Patterns
        \(bulletList(from: roseTexts, fallback: "No rose moments captured."))

        ## Bud Momentum
        \(bulletList(from: budTexts, fallback: "No bud moments captured."))

        ## Thorn Themes
        \(bulletList(from: thornTexts, fallback: "No thorn moments captured."))

        ## Notable Quotes
        \(quoteLines.joined(separator: "\n"))

        ## Photo Moments
        \(photoLines.joined(separator: "\n"))

        ## Suggested Focus
        \(suggestedFocus(from: highlights))
        """
    }

    private func bulletList(from values: [String], fallback: String) -> String {
        let lines = values.prefix(5).map { "- \($0)" }
        return lines.isEmpty ? "- \(fallback)" : lines.joined(separator: "\n")
    }

    private func suggestedFocus(from highlights: [String]) -> String {
        guard let first = highlights.first else {
            return "- Continue daily reflection and build consistency."
        }
        return "- Lean into \(first) while planning around recurring thorns."
    }
}
