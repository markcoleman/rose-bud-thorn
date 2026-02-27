import Foundation
import CoreModels

public struct HighlightExtractor: Sendable {
    private let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "to", "of", "in", "on", "for", "with", "is", "it", "that", "this", "i", "we", "you", "my", "our", "was", "were", "be", "as", "at", "from", "by", "about", "today"
    ]

    public init() {}

    public func extract(from entries: [EntryDay], limit: Int = 8) -> [String] {
        guard !entries.isEmpty else {
            return []
        }

        var scoreByToken: [String: Double] = [:]

        for (offset, entry) in entries.enumerated() {
            let recencyWeight = 1.0 + (Double(entries.count - offset) / Double(entries.count))
            for type in EntryType.allCases {
                let item = entry.item(for: type)
                let shortTokens = tokenize(item.shortText)
                let journalTokens = tokenize(item.journalTextMarkdown)

                for token in shortTokens {
                    scoreByToken[token, default: 0] += 2.0 * recencyWeight
                }
                for token in journalTokens {
                    scoreByToken[token, default: 0] += 1.0 * recencyWeight
                }
            }
        }

        return scoreByToken
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(limit)
            .map(\.key)
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }
}
