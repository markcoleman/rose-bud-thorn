import XCTest

final class RoseBudThornUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesTodayScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].waitForExistence(timeout: 6) || app.staticTexts["Today"].waitForExistence(timeout: 6))
    }
}
