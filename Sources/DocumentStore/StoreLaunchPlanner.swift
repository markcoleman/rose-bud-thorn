import Foundation

public enum StoreLaunchMode: String, Sendable, Equatable {
    case iCloud
    case appGroup
}

public struct StoreLaunchDecision: Sendable, Equatable {
    public let mode: StoreLaunchMode
    public let shouldPromptMigration: Bool
    public let shouldMarkMigrationComplete: Bool

    public init(
        mode: StoreLaunchMode,
        shouldPromptMigration: Bool,
        shouldMarkMigrationComplete: Bool
    ) {
        self.mode = mode
        self.shouldPromptMigration = shouldPromptMigration
        self.shouldMarkMigrationComplete = shouldMarkMigrationComplete
    }
}

public enum StoreLaunchPlanner {
    public static func decide(
        iCloudAvailable: Bool,
        migrationCompleted: Bool,
        appGroupHasCanonicalData: Bool
    ) -> StoreLaunchDecision {
        guard iCloudAvailable else {
            return StoreLaunchDecision(
                mode: .appGroup,
                shouldPromptMigration: false,
                shouldMarkMigrationComplete: false
            )
        }

        if migrationCompleted {
            return StoreLaunchDecision(
                mode: .iCloud,
                shouldPromptMigration: false,
                shouldMarkMigrationComplete: false
            )
        }

        if appGroupHasCanonicalData {
            return StoreLaunchDecision(
                mode: .appGroup,
                shouldPromptMigration: true,
                shouldMarkMigrationComplete: false
            )
        }

        return StoreLaunchDecision(
            mode: .iCloud,
            shouldPromptMigration: false,
            shouldMarkMigrationComplete: true
        )
    }
}
