import Foundation
import CoreModels

public struct DayShareCardSelection: Hashable, Sendable {
    public let type: EntryType
    public let ref: PhotoRef
    public let sourceURL: URL

    public init(type: EntryType, ref: PhotoRef, sourceURL: URL) {
        self.type = type
        self.ref = ref
        self.sourceURL = sourceURL
    }
}

public struct DayShareCardPayload: Identifiable, Sendable {
    public let dayKey: LocalDayKey
    public let dayTitle: String
    public let rose: DayShareCardSelection
    public let bud: DayShareCardSelection
    public let thorn: DayShareCardSelection
    public let outputURL: URL
    public let messageBody: String

    public init(
        dayKey: LocalDayKey,
        dayTitle: String,
        rose: DayShareCardSelection,
        bud: DayShareCardSelection,
        thorn: DayShareCardSelection,
        outputURL: URL,
        messageBody: String
    ) {
        self.dayKey = dayKey
        self.dayTitle = dayTitle
        self.rose = rose
        self.bud = bud
        self.thorn = thorn
        self.outputURL = outputURL
        self.messageBody = messageBody
    }

    public var id: String {
        outputURL.path
    }

    public var selections: [DayShareCardSelection] {
        [rose, bud, thorn]
    }

    public var outputTypeIdentifier: String {
        "public.png"
    }
}
