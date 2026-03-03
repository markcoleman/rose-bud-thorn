import XCTest

final class CaptureDayFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureAndExpandFlow() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        let roseField = app.textFields["Rose for today"]
        XCTAssertTrue(roseField.waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["Capture media for Rose"].isHittable)
        XCTAssertTrue(app.buttons["Capture media for Bud"].isHittable)
        XCTAssertTrue(app.buttons["Capture media for Thorn"].isHittable)
        roseField.tap()
        roseField.typeText("Great coffee")

        let moreButton = app.buttons["More…"].firstMatch
        if moreButton.exists {
            moreButton.tap()
        }

        let doneButton = app.buttons["Done"].firstMatch
        if doneButton.exists {
            doneButton.tap()
        }

        app.tabBars.buttons["Browse"].tap()
        XCTAssertTrue(app.navigationBars["Browse"].waitForExistence(timeout: 4))

        let timelineMode = app.buttons["Timeline"]
        if timelineMode.exists {
            timelineMode.tap()
        }

        let timelineCard = app.otherElements["browse-timeline-card"].firstMatch
        if timelineCard.waitForExistence(timeout: 3) {
            timelineCard.tap()
            XCTAssertTrue(app.buttons["Save"].firstMatch.waitForExistence(timeout: 4))
            let backButton = app.navigationBars.buttons["Browse"].firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }

        let calendarMode = app.buttons["Calendar"]
        if calendarMode.exists {
            calendarMode.tap()
        }

        let dayButtonPredicate = NSPredicate(format: "label BEGINSWITH 'Day '")
        let dayButton = app.buttons.matching(dayButtonPredicate).firstMatch
        if dayButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(dayButton.isHittable)
        }

        let olderEntryButton = app.buttons["Older Entry"].firstMatch
        if olderEntryButton.exists {
            XCTAssertTrue(olderEntryButton.isHittable)
        }

        let newerEntryButton = app.buttons["Newer Entry"].firstMatch
        if newerEntryButton.exists {
            XCTAssertTrue(newerEntryButton.isHittable)
        }

        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].waitForExistence(timeout: 4))

        let searchButton = app.buttons["Search"].firstMatch
        XCTAssertTrue(searchButton.exists)
        XCTAssertTrue(searchButton.isHittable)
    }
}
