import Foundation
import CoreModels

struct IndexDocument: Codable, Sendable {
    var dayKey: LocalDayKey
    var updatedAt: Date
    var roseText: String
    var budText: String
    var thornText: String
    var roseHasPhoto: Bool
    var budHasPhoto: Bool
    var thornHasPhoto: Bool

    init(entry: EntryDay) {
        dayKey = entry.dayKey
        updatedAt = entry.updatedAt
        roseText = entry.roseItem.combinedText
        budText = entry.budItem.combinedText
        thornText = entry.thornItem.combinedText
        roseHasPhoto = entry.roseItem.hasPhotos
        budHasPhoto = entry.budItem.hasPhotos
        thornHasPhoto = entry.thornItem.hasPhotos
    }

    func text(for categories: Set<EntryType>) -> String {
        let categoriesToUse = categories.isEmpty ? Set(EntryType.allCases) : categories
        return categoriesToUse.reduce(into: [String]()) { partialResult, type in
            switch type {
            case .rose:
                partialResult.append(roseText)
            case .bud:
                partialResult.append(budText)
            case .thorn:
                partialResult.append(thornText)
            }
        }.joined(separator: "\n")
    }

    var hasAnyPhoto: Bool {
        roseHasPhoto || budHasPhoto || thornHasPhoto
    }

    var hasNoPhoto: Bool {
        !hasAnyPhoto
    }
}
