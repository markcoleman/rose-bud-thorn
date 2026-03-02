import Foundation

public extension EntryItem {
    var hasAnyContent: Bool {
        !shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        hasMedia
    }
}

public extension EntryDay {
    var isRoseComplete: Bool {
        roseItem.hasAnyContent
    }

    var isBudComplete: Bool {
        budItem.hasAnyContent
    }

    var isThornComplete: Bool {
        thornItem.hasAnyContent
    }

    var completionCount: Int {
        [isRoseComplete, isBudComplete, isThornComplete].filter { $0 }.count
    }

    var isCompleteForDailyCapture: Bool {
        completionCount == EntryType.allCases.count
    }
}
