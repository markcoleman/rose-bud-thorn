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

        let dayCard = journalDayCardButton(in: app)
        XCTAssertTrue(dayCard.exists)
        dayCard.tap()

        let pager = dayPolaroidPager(in: app)
        XCTAssertTrue(pager.exists)
        XCTAssertTrue(app.buttons["day-edit-button"].waitForExistence(timeout: 4))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertFalse(app.buttons["Open memory"].exists)

        tapTabBarButton(titled: "Insights", in: app)

        let moreButton = app.buttons["insights-more-button"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 6))
        moreButton.tap()
        app.buttons["insights-more-settings"].tap()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 6))
        let settingsDoneButton = app.buttons["settings-sheet-close"]
        XCTAssertTrue(settingsDoneButton.waitForExistence(timeout: 4))
        settingsDoneButton.tap()
    }
}
