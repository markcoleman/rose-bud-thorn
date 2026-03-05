import XCTest

final class JournalFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchEditTodayOpenPastDayBackAndSearch() {
        let app = launchAppForUITests(
            resetOnboarding: true,
            onboardingCountdownSeconds: 6,
            seedJournalData: true
        )
        dismissOnboardingIfPresented(app)

        XCTAssertTrue(app.navigationBars["Journal"].waitForExistence(timeout: 6))

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

        let searchField = app.textFields["Search entries"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 4))
        searchField.tap()
        searchField.typeText("Seeded yesterday")

        XCTAssertTrue(dayCard.waitForExistence(timeout: 6))
    }
}
