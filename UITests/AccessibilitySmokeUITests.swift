import XCTest

final class AccessibilitySmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPrimaryCaptureControlsAreAccessible() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.otherElements["today-completion-progress"].exists)
        XCTAssertTrue(app.textFields["Bud for today"].exists)
        XCTAssertTrue(app.textFields["Thorn for today"].exists)
        let roseCapture = app.buttons["Capture media for Rose"]
        let budCapture = app.buttons["Capture media for Bud"]
        let thornCapture = app.buttons["Capture media for Thorn"]
        XCTAssertTrue(roseCapture.exists)
        XCTAssertTrue(budCapture.exists)
        XCTAssertTrue(thornCapture.exists)
        XCTAssertTrue(roseCapture.isHittable)
        XCTAssertTrue(budCapture.isHittable)
        XCTAssertTrue(thornCapture.isHittable)
    }

    func testCoreTabNavigationDiscoverability() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        XCTAssertTrue(app.otherElements["floating-tab-bar"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["floating-tab-journal"].exists)
        XCTAssertTrue(app.buttons["floating-tab-insights"].exists)

        app.buttons["floating-tab-journal"].tap()
        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["journal-settings-button"].exists)

        app.buttons["floating-tab-insights"].tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["insights-more-button"].exists)
        app.buttons["insights-more-button"].tap()
        XCTAssertTrue(app.buttons["insights-more-settings"].waitForExistence(timeout: 4))
    }

    func testEngagementActionsAreHittableWhenPresent() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        let actions = [
            "View Day Details",
            "Then vs Now",
            "Snooze",
            "Dismiss",
        ]

        for action in actions {
            let button = app.buttons[action].firstMatch
            if button.exists {
                XCTAssertTrue(button.isHittable, "Expected \(action) to be hittable when shown.")
            }
        }
    }

    func testBrowseFeedThumbnailIsDiscoverableWhenShown() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6, seedJournalData: true)
        dismissOnboardingIfPresented(app)

        app.buttons["floating-tab-journal"].tap()
        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 4))
        app.swipeUp()

        let thumbnail = app.images.firstMatch
        if thumbnail.waitForExistence(timeout: 2) {
            XCTAssertTrue(thumbnail.isHittable)
        }
    }
}
