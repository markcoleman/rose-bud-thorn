import XCTest

final class AccessibilitySmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPrimaryCaptureControlsAreAccessible() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 6))
        XCTAssertTrue(app.textFields["Bud for today"].exists)
        XCTAssertTrue(app.textFields["Thorn for today"].exists)
        XCTAssertTrue(app.buttons["Capture media for Rose"].exists)
    }
}
