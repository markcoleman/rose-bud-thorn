import Foundation
import CoreModels

public struct IndexMapper: Sendable {
    public init() {}

    public func searchableText(for entry: EntryDay, categories: Set<EntryType>) -> String {
        let categoriesToUse = categories.isEmpty ? Set(EntryType.allCases) : categories
        return categoriesToUse.map { entry.item(for: $0).combinedText }.joined(separator: "\n")
    }
}
