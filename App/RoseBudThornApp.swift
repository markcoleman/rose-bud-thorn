import SwiftUI
import AppFeatures
import DocumentStore

// Xcode app-target wrapper entrypoint.
@main
struct RoseBudThornApp: App {
    private let environment = Self.makeEnvironment()

    var body: some Scene {
        WindowGroup {
            if let environment {
                RootAppView(environment: environment)
            } else {
                ContentUnavailableView("Startup Failed", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private static func makeEnvironment() -> AppEnvironment? {
        do {
            let legacyConfiguration = try DocumentStoreConfiguration.legacyLive()
            let sharedConfiguration = try DocumentStoreConfiguration.appGroup(
                appGroupID: AppGroupConstants.appGroupIdentifier
            )
            try StoreLocationMigrator.migrateLegacyStoreIfNeeded(
                from: legacyConfiguration.rootURL,
                to: sharedConfiguration.rootURL,
                defaults: .standard,
                migrationKey: AppGroupConstants.migrationDefaultsKey
            )
            return try AppEnvironment(configuration: sharedConfiguration)
        } catch {
            return nil
        }
    }
}
