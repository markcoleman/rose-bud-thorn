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

        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.tabBars.buttons["Browse"].exists)
        XCTAssertTrue(app.tabBars.buttons["Summaries"].exists)
        XCTAssertTrue(app.tabBars.buttons["Search"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)

        app.tabBars.buttons["Browse"].tap()
        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 4))

        app.tabBars.buttons["Summaries"].tap()
        XCTAssertTrue(app.navigationBars["Summaries"].waitForExistence(timeout: 4))

        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 4))
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
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        app.tabBars.buttons["Browse"].tap()
        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 4))

        let thumbnail = app.otherElements["browse-feed-thumbnail"].firstMatch
        if thumbnail.waitForExistence(timeout: 2) {
            XCTAssertTrue(thumbnail.isHittable)
        }
    }
}
