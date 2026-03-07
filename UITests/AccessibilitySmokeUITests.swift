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
        let roseLibrary = app.buttons["reflection-rose-library-button"]
        let roseCamera = app.buttons["reflection-rose-camera-button"]
        let budLibrary = app.buttons["reflection-bud-library-button"]
        let budCamera = app.buttons["reflection-bud-camera-button"]
        let thornLibrary = app.buttons["reflection-thorn-library-button"]
        let thornCamera = app.buttons["reflection-thorn-camera-button"]

        XCTAssertTrue(roseLibrary.exists)
        XCTAssertTrue(roseCamera.exists)
        XCTAssertTrue(budLibrary.exists)
        XCTAssertTrue(budCamera.exists)
        XCTAssertTrue(thornLibrary.exists)
        XCTAssertTrue(thornCamera.exists)

        XCTAssertTrue(roseLibrary.isHittable)
        XCTAssertTrue(roseCamera.isHittable)
        XCTAssertTrue(budLibrary.isHittable)
        XCTAssertTrue(budCamera.isHittable)
        XCTAssertTrue(thornLibrary.isHittable)
        XCTAssertTrue(thornCamera.isHittable)
    }

    func testCoreTabNavigationDiscoverability() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        let journalTab = tabBarButton(titled: "Journal", in: app)
        let insightsTab = tabBarButton(titled: "Insights", in: app)
        XCTAssertTrue(journalTab.waitForExistence(timeout: 6))
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 6))

        journalTab.tap()
        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["journal-settings-button"].exists)

        insightsTab.tap()
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

        tapTabBarButton(titled: "Journal", in: app)
        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 4))
        app.swipeUp()

        let thumbnail = app.images.firstMatch
        if thumbnail.waitForExistence(timeout: 2) {
            XCTAssertTrue(thumbnail.isHittable)
        }
    }
}
