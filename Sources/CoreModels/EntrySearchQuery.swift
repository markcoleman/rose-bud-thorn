import Foundation

public struct EntrySearchQuery: Hashable, Sendable {
    public let text: String
    public let categories: Set<EntryType>
    public let hasPhoto: Bool?
    public let dateRange: DateInterval?

    public init(
        text: String,
        categories: Set<EntryType> = Set(EntryType.allCases),
        hasPhoto: Bool? = nil,
        dateRange: DateInterval? = nil
    ) {
        self.text = text
        self.categories = categories
        self.hasPhoto = hasPhoto
        self.dateRange = dateRange
    }
}
