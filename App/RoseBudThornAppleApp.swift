import SwiftUI
import AppFeatures
import DocumentStore

@main
struct RoseBudThornAppleApp: App {
    @State private var launchState: AppLaunchState

    init() {
        _launchState = State(initialValue: Self.bootstrap())
    }

    var body: some Scene {
        WindowGroup {
            rootContent
                .alert("Move Existing Data to iCloud?", isPresented: migrationPromptBinding) {
                    Button("Later", role: .cancel) {
                        launchState.shouldPromptMigration = false
                        launchState.migrationErrorMessage = nil
                    }
                    Button("Migrate Now") {
                        migrateToICloudNow()
                    }
                } message: {
                    Text(migrationPromptMessage)
                }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if let environment = launchState.environment {
            RootAppView(
                environment: environment,
                onWillBecomeActive: bridgeAppGroupIntoICloudIfNeeded
            )
        } else {
            ContentUnavailableView(
                "Startup Failed",
                systemImage: "exclamationmark.triangle",
                description: Text(launchState.bootError ?? "Unknown startup error.")
            )
        }
    }

    private var migrationPromptBinding: Binding<Bool> {
        Binding(
            get: {
                launchState.shouldPromptMigration
            },
            set: { newValue in
                launchState.shouldPromptMigration = newValue
                if !newValue {
                    launchState.migrationErrorMessage = nil
                }
            }
        )
    }

    private var migrationPromptMessage: String {
        if let migrationErrorMessage = launchState.migrationErrorMessage {
            return "Couldn't migrate existing data to iCloud. \(migrationErrorMessage)\n\nYou can retry now or choose Later."
        }
        return "Migrate your existing moments (images and metadata) from local storage to iCloud so they can sync across iPhone, iPad, and Mac."
    }

    private func migrateToICloudNow(defaults: UserDefaults = .standard) {
        guard let appGroupConfiguration = launchState.appGroupConfiguration,
              let iCloudConfiguration = launchState.iCloudConfiguration else {
            launchState.shouldPromptMigration = false
            return
        }

        do {
            try StoreLocationMigrator.mergeStoreContents(
                from: appGroupConfiguration.rootURL,
                to: iCloudConfiguration.rootURL
            )
            let environment = try AppEnvironment(configuration: iCloudConfiguration)
            defaults.set(true, forKey: AppGroupConstants.iCloudMigrationDefaultsKey)
            launchState.environment = environment
            launchState.activeMode = .iCloud
            launchState.shouldPromptMigration = false
            launchState.migrationErrorMessage = nil
        } catch {
            launchState.migrationErrorMessage = error.localizedDescription
            launchState.shouldPromptMigration = true
        }
    }

    private func bridgeAppGroupIntoICloudIfNeeded() {
        guard launchState.activeMode == .iCloud,
              let appGroupConfiguration = launchState.appGroupConfiguration,
              let iCloudConfiguration = launchState.iCloudConfiguration else {
            return
        }

        guard StoreLocationMigrator.hasCanonicalData(at: appGroupConfiguration.rootURL) else {
            return
        }

        try? StoreLocationMigrator.mergeStoreContents(
            from: appGroupConfiguration.rootURL,
            to: iCloudConfiguration.rootURL
        )
    }

    private static func bootstrap(defaults: UserDefaults = .standard) -> AppLaunchState {
        do {
            let appGroupConfiguration = try DocumentStoreConfiguration.appGroup(
                appGroupID: AppGroupConstants.appGroupIdentifier
            )
            let iCloudConfiguration = try DocumentStoreConfiguration.iCloudDocuments(
                containerIdentifier: AppGroupConstants.iCloudContainerIdentifier
            )

            let migrationCompleted = defaults.bool(forKey: AppGroupConstants.iCloudMigrationDefaultsKey)
            let appGroupHasCanonicalData = StoreLocationMigrator.hasCanonicalData(at: appGroupConfiguration.rootURL)
            let decision = StoreLaunchPlanner.decide(
                iCloudAvailable: iCloudConfiguration != nil,
                migrationCompleted: migrationCompleted,
                appGroupHasCanonicalData: appGroupHasCanonicalData
            )

            if decision.shouldMarkMigrationComplete {
                defaults.set(true, forKey: AppGroupConstants.iCloudMigrationDefaultsKey)
            }

            let activeConfiguration: DocumentStoreConfiguration
            let activeMode: StoreLaunchMode
            switch decision.mode {
            case .iCloud:
                activeConfiguration = iCloudConfiguration ?? appGroupConfiguration
                activeMode = iCloudConfiguration == nil ? .appGroup : .iCloud
            case .appGroup:
                activeConfiguration = appGroupConfiguration
                activeMode = .appGroup
            }

            let environment = try AppEnvironment(configuration: activeConfiguration)
            return AppLaunchState(
                environment: environment,
                bootError: nil,
                appGroupConfiguration: appGroupConfiguration,
                iCloudConfiguration: iCloudConfiguration,
                activeMode: activeMode,
                shouldPromptMigration: decision.shouldPromptMigration,
                migrationErrorMessage: nil
            )
        } catch {
            return AppLaunchState(
                environment: nil,
                bootError: error.localizedDescription,
                appGroupConfiguration: nil,
                iCloudConfiguration: nil,
                activeMode: .appGroup,
                shouldPromptMigration: false,
                migrationErrorMessage: nil
            )
        }
    }
}

private struct AppLaunchState {
    var environment: AppEnvironment?
    var bootError: String?
    var appGroupConfiguration: DocumentStoreConfiguration?
    var iCloudConfiguration: DocumentStoreConfiguration?
    var activeMode: StoreLaunchMode
    var shouldPromptMigration: Bool
    var migrationErrorMessage: String?
}
