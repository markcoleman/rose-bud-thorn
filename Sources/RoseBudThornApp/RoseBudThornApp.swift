import SwiftUI
import AppFeatures

@main
struct RoseBudThornAppMain: App {
    private let environment: AppEnvironment?
    private let bootError: String?

    init() {
        do {
            self.environment = try AppEnvironment.live()
            self.bootError = nil
        } catch {
            self.environment = nil
            self.bootError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let environment {
                RootAppView(environment: environment)
            } else {
                ContentUnavailableView("Startup Failed", systemImage: "exclamationmark.triangle", description: Text(bootError ?? "Unknown error"))
            }
        }
    }
}
