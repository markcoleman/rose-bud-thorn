import XCTest

extension XCTestCase {
    @discardableResult
    func launchAppForUITests(
        resetOnboarding: Bool = false,
        onboardingCountdownSeconds: Int? = nil,
        seedJournalData: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        if resetOnboarding {
            app.launchArguments.append("-reset-onboarding")
        }
        if seedJournalData {
            app.launchArguments.append("-seed-journal-ui-data")
        }
        if let onboardingCountdownSeconds {
            app.launchArguments.append("-onboarding-countdown-seconds")
            app.launchArguments.append(String(onboardingCountdownSeconds))
        }
        app.launch()
        return app
    }

    func dismissOnboardingIfPresented(_ app: XCUIApplication, timeout: TimeInterval = 2) {
        let skip = app.buttons["onboarding-skip"]
        if skip.waitForExistence(timeout: timeout) {
            skip.tap()
            return
        }

        let close = app.buttons["onboarding-close"]
        if close.waitForExistence(timeout: 0.5) {
            close.tap()
            return
        }

        let start = app.buttons["onboarding-start"]
        if start.waitForExistence(timeout: 0.5) {
            start.tap()
        }
    }
}
