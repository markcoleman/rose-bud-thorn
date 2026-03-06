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

        let indicator = app.otherElements["onboarding-page-indicator"]
        XCTAssertTrue(indicator.waitForExistence(timeout: 4))
        XCTAssertEqual(indicator.label, "Page 1 of 3")

        app.swipeLeft()
        expectation(for: NSPredicate(format: "label == %@", "Page 2 of 3"), evaluatedWith: indicator)
        waitForExpectations(timeout: 4)
    }

    func testOnboardingCountdownAutoAdvances() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 2)

        let indicator = app.otherElements["onboarding-page-indicator"]
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

        app.buttons["floating-tab-insights"].tap()

        let moreButton = app.buttons["insights-more-button"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 6))
        moreButton.tap()
        app.buttons["insights-more-settings"].tap()

        let replayButton = app.buttons["Replay onboarding"]
        XCTAssertTrue(replayButton.waitForExistence(timeout: 6))
        replayButton.tap()

        XCTAssertTrue(app.otherElements["onboarding-page-indicator"].waitForExistence(timeout: 4))
    }
}
