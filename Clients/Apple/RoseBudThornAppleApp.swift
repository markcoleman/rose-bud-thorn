import SwiftUI
import AppFeatures

@main
struct RoseBudThornAppleApp: App {
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
