import Foundation

public extension EntryItem {
    var hasAnyContent: Bool {
        !shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !journalTextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        hasMedia
    }
}

public extension EntryDay {
    var isCompleteForDailyCapture: Bool {
        roseItem.hasAnyContent || budItem.hasAnyContent || thornItem.hasAnyContent
    }
}
