import Foundation
import CoreModels

public enum InsightPeriod: String, Codable, CaseIterable, Sendable {
    case week
    case month
}

public enum InsightCardType: String, Codable, CaseIterable, Sendable {
    case consistency
    case dominantCategory
    case tagMomentum
    case moodTrend
}

public struct InsightCard: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let type: InsightCardType
    public let period: InsightPeriod
    public let key: String
    public let title: String
    public let body: String
    public let explainability: String
    public let generatedAt: Date

    public init(
        id: String,
        type: InsightCardType,
        period: InsightPeriod,
        key: String,
        title: String,
        body: String,
        explainability: String,
        generatedAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.period = period
        self.key = key
        self.title = title
        self.body = body
        self.explainability = explainability
        self.generatedAt = generatedAt
    }
}

public struct ResurfacedMemory: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let sourceDayKey: LocalDayKey
    public let type: EntryType
    public let excerpt: String
    public let thenVsNowPrompt: String

    public init(
        id: String,
        sourceDayKey: LocalDayKey,
        type: EntryType,
        excerpt: String,
        thenVsNowPrompt: String
    ) {
        self.id = id
        self.sourceDayKey = sourceDayKey
        self.type = type
        self.excerpt = excerpt
        self.thenVsNowPrompt = thenVsNowPrompt
    }
}

public enum ResurfacingAction: String, Codable, CaseIterable, Sendable {
    case dismiss
    case snooze
}

public struct ResurfacingDecision: Codable, Hashable, Sendable {
    public let memoryID: String
    public let sourceDayKey: LocalDayKey
    public let action: ResurfacingAction
    public let decidedAt: Date
    public let cooldownUntil: LocalDayKey

    public init(
        memoryID: String,
        sourceDayKey: LocalDayKey,
        action: ResurfacingAction,
        decidedAt: Date = .now,
        cooldownUntil: LocalDayKey
    ) {
        self.memoryID = memoryID
        self.sourceDayKey = sourceDayKey
        self.action = action
        self.decidedAt = decidedAt
        self.cooldownUntil = cooldownUntil
    }
}

public enum CommitmentStatus: String, Codable, CaseIterable, Sendable {
    case planned
    case completed
}

public struct WeeklyCommitment: Codable, Equatable, Sendable {
    public let weekKey: String
    public let text: String
    public let status: CommitmentStatus
    public let updatedAt: Date
    public let completedAt: Date?

    public init(
        weekKey: String,
        text: String,
        status: CommitmentStatus,
        updatedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.weekKey = weekKey
        self.text = text
        self.status = status
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
}
