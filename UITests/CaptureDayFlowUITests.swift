import XCTest

final class CaptureDayFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testJournalFlowLaunchEditOpenDetailBackAndSearch() {
        let app = launchAppForUITests(
            resetOnboarding: true,
            onboardingCountdownSeconds: 6,
            seedJournalData: true
        )
        dismissOnboardingIfPresented(app)

        let roseField = app.textFields["Rose for today"]
        XCTAssertTrue(roseField.waitForExistence(timeout: 6))
        roseField.tap()
        roseField.typeText("Great coffee from Journal")

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
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 4))
        backButton.tap()
        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 4))
    }
}
