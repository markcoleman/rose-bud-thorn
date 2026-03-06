import XCTest

final class JournalFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchEditTodayOpenPastDayBackAndOpenInsightsSettings() {
        let app = launchAppForUITests(
            resetOnboarding: true,
            onboardingCountdownSeconds: 6,
            seedJournalData: true
        )
        dismissOnboardingIfPresented(app)

        let roseField = app.textFields["Rose for today"]
        XCTAssertTrue(roseField.waitForExistence(timeout: 6))
        roseField.tap()
        roseField.typeText("Journal flow test text")

        let doneButton = app.buttons["Done"].firstMatch
        if doneButton.exists {
            doneButton.tap()
        }

        app.swipeUp()
        let dayCard = app.otherElements["journal-day-card"].firstMatch
        XCTAssertTrue(dayCard.waitForExistence(timeout: 6))
        dayCard.tap()

        XCTAssertTrue(app.otherElements["day-polaroid-pager"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["day-edit-button"].waitForExistence(timeout: 4))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertFalse(app.buttons["Open memory"].exists)

        let insightsTab = app.buttons["floating-tab-insights"]
        XCTAssertTrue(insightsTab.waitForExistence(timeout: 4))
        insightsTab.tap()

        let moreButton = app.buttons["insights-more-button"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 6))
        moreButton.tap()
        app.buttons["insights-more-settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 6))
        let doneButton = app.buttons["settings-sheet-close"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 4))
        doneButton.tap()
    }
}
