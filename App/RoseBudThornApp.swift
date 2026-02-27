import SwiftUI
import AppFeatures

// Xcode app-target wrapper entrypoint.
@main
struct RoseBudThornApp: App {
    private let environment = try? AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            if let environment {
                RootAppView(environment: environment)
            } else {
                ContentUnavailableView("Startup Failed", systemImage: "exclamationmark.triangle")
            }
        }
    }
}
