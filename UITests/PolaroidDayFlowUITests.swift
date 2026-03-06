import XCTest

final class PolaroidDayFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOpenDayFlipShareAndShowRemoveConfirmation() {
        let app = launchAppForUITests(
            resetOnboarding: true,
            onboardingCountdownSeconds: 6,
            seedJournalData: true
        )
        dismissOnboardingIfPresented(app)

        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 6))
        app.swipeUp()

        let dayCard = app.otherElements["journal-day-card"].firstMatch
        XCTAssertTrue(dayCard.waitForExistence(timeout: 6))
        dayCard.tap()

        let pager = app.otherElements["day-polaroid-pager"]
        XCTAssertTrue(pager.waitForExistence(timeout: 6))
        XCTAssertTrue(app.otherElements["day-reflection-segmented"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.otherElements["floating-tab-bar"].exists)

        pager.swipeLeft()
        XCTAssertTrue(app.otherElements["day-polaroid-card-bud"].waitForExistence(timeout: 4))
        pager.swipeLeft()
        XCTAssertTrue(app.otherElements["day-polaroid-card-thorn"].waitForExistence(timeout: 4))

        let shareButton = app.buttons["day-share-button"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 4))
        shareButton.tap()

        let activityList = app.otherElements["ActivityListView"].firstMatch
        let sheet = app.sheets.firstMatch
        let sharePresented = activityList.waitForExistence(timeout: 6) || sheet.waitForExistence(timeout: 6)
        XCTAssertTrue(sharePresented)

        dismissShareUIIfNeeded(app)

        let moreButton = app.buttons["day-more-actions"].firstMatch
        XCTAssertTrue(moreButton.waitForExistence(timeout: 4))
        moreButton.tap()

        let removeButton = app.buttons["Remove"].firstMatch
        XCTAssertTrue(removeButton.waitForExistence(timeout: 4))
        removeButton.tap()

        XCTAssertTrue(app.staticTexts["Remove this day?"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Cancel"].exists)
        app.buttons["Cancel"].tap()
    }

    private func dismissShareUIIfNeeded(_ app: XCUIApplication) {
        let close = app.buttons["Close"].firstMatch
        if close.waitForExistence(timeout: 1) {
            close.tap()
            return
        }

        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 1) {
            cancel.tap()
            return
        }

        app.swipeDown()
    }
}
