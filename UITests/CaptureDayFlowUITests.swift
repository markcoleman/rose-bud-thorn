import XCTest

final class CaptureDayFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureAndExpandFlow() {
        let app = XCUIApplication()
        app.launch()

        let roseField = app.textFields["Rose for today"]
        XCTAssertTrue(roseField.waitForExistence(timeout: 6))
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
    }
}
