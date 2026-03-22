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
        XCTAssertTrue(element(withIdentifier: "journal-active-prompt", in: app).exists)

        let addPhoto = app.buttons["journal-add-photo-button"]
        let camera = app.buttons["journal-camera-button"]
        let voice = app.buttons["journal-voice-button"]
        let continueButton = app.buttons["journal-continue-button"]
        let rosePill = app.buttons["journal-type-pill-rose"]
        let budPill = app.buttons["journal-type-pill-bud"]
        let thornPill = app.buttons["journal-type-pill-thorn"]

        XCTAssertTrue(addPhoto.exists)
        XCTAssertTrue(camera.exists)
        XCTAssertTrue(voice.exists)
        XCTAssertTrue(continueButton.exists)
        XCTAssertTrue(rosePill.exists)
        XCTAssertTrue(budPill.exists)
        XCTAssertTrue(thornPill.exists)

        XCTAssertTrue(addPhoto.isHittable)
        XCTAssertTrue(camera.isHittable)
        XCTAssertFalse(voice.isEnabled)

        let roseField = app.textFields["Rose for today"]
        roseField.tap()
        roseField.typeText("Accessibility flow")
        XCTAssertTrue(continueButton.isHittable)
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
