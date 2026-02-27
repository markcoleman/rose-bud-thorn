import Foundation

public struct LocalDayKey: Codable, Hashable, Sendable, Comparable {
    public let isoDate: String
    public let timeZoneID: String

    public init(isoDate: String, timeZoneID: String) {
        self.isoDate = isoDate
        self.timeZoneID = timeZoneID
    }

    public static func < (lhs: LocalDayKey, rhs: LocalDayKey) -> Bool {
        if lhs.isoDate == rhs.isoDate {
            return lhs.timeZoneID < rhs.timeZoneID
        }
        return lhs.isoDate < rhs.isoDate
    }

    public var year: String {
        String(isoDate.prefix(4))
    }

    public var month: String {
        let start = isoDate.index(isoDate.startIndex, offsetBy: 5)
        let end = isoDate.index(start, offsetBy: 2)
        return String(isoDate[start..<end])
    }

    public var day: String {
        let start = isoDate.index(isoDate.startIndex, offsetBy: 8)
        let end = isoDate.index(start, offsetBy: 2)
        return String(isoDate[start..<end])
    }
}
