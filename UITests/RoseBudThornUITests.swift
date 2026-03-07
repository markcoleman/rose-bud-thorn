import XCTest

final class RoseBudThornUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLaunchShowsOnboardingThenSkipOpensToday() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 4)

        XCTAssertTrue(app.buttons["onboarding-skip"].waitForExistence(timeout: 4))
        app.buttons["onboarding-skip"].tap()

        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 6))
    }

    func testOnboardingSwipeUpdatesPageIndicator() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 8)

        let indicator = element(withIdentifier: "onboarding-page-indicator", in: app)
        XCTAssertTrue(indicator.waitForExistence(timeout: 4))
        XCTAssertEqual(indicator.label, "Page 1 of 3")

        app.swipeLeft()
        expectation(for: NSPredicate(format: "label == %@", "Page 2 of 3"), evaluatedWith: indicator)
        waitForExpectations(timeout: 4)
    }

    func testOnboardingCountdownAutoAdvances() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 2)

        let indicator = element(withIdentifier: "onboarding-page-indicator", in: app)
        XCTAssertTrue(indicator.waitForExistence(timeout: 4))
        expectation(for: NSPredicate(format: "label == %@", "Page 2 of 3"), evaluatedWith: indicator)
        waitForExpectations(timeout: 6)
    }

    func testOnboardingLastScreenCanCloseWithX() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 8)

        XCTAssertTrue(app.buttons["onboarding-next"].waitForExistence(timeout: 4))
        app.buttons["onboarding-next"].tap()
        XCTAssertTrue(app.buttons["onboarding-next"].waitForExistence(timeout: 4))
        app.buttons["onboarding-next"].tap()

        let closeButton = app.buttons["onboarding-close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 4))
        closeButton.tap()

        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 6))
    }

    func testSettingsReplayOnboardingReopensFlow() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        tapTabBarButton(titled: "Insights", in: app)

        let moreButton = app.buttons["insights-more-button"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 6))
        moreButton.tap()
        app.buttons["insights-more-settings"].tap()

        let replayButton = app.buttons["settings-replay-onboarding"].firstMatch
        if !replayButton.waitForExistence(timeout: 2) || !replayButton.isHittable {
            _ = scrollToElement(replayButton, in: app)
        }
        XCTAssertTrue(replayButton.exists)
        replayButton.tap()

        XCTAssertTrue(element(withIdentifier: "onboarding-page-indicator", in: app).waitForExistence(timeout: 4))
    }
}
