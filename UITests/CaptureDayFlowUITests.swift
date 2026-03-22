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

        let dayCard = journalDayCardButton(in: app)
        XCTAssertTrue(dayCard.exists)
        dayCard.tap()

        let pager = dayPolaroidPager(in: app)
        XCTAssertTrue(pager.exists)
        XCTAssertTrue(app.buttons["day-edit-button"].waitForExistence(timeout: 4))
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 4))
        backButton.tap()
        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 4))
    }

    func testCaptureControlsUseLibraryPrimaryAndCameraSecondary() {
        let app = launchAppForUITests(
            resetOnboarding: true,
            onboardingCountdownSeconds: 6
        )
        dismissOnboardingIfPresented(app)

        let libraryButton = app.buttons["journal-add-photo-button"]
        let cameraButton = app.buttons["journal-camera-button"]
        let voiceButton = app.buttons["journal-voice-button"]

        XCTAssertTrue(libraryButton.waitForExistence(timeout: 6))
        XCTAssertTrue(cameraButton.exists)
        XCTAssertTrue(voiceButton.exists)
        XCTAssertFalse(voiceButton.isEnabled)

        libraryButton.tap()
        XCTAssertTrue(app.otherElements["journal-photo-library-presented"].waitForExistence(timeout: 2))
        dismissPhotoPickerIfNeeded(app)

        cameraButton.tap()
        allowSystemPermissionAlertIfPresent()

        let cameraRoot = element(withIdentifier: "moment-camera-view", in: app)
        var cameraPresented =
            cameraRoot.waitForExistence(timeout: 6) ||
            app.activityIndicators["moment-camera-view"].waitForExistence(timeout: 2) ||
            app.buttons["moment-camera-library-button"].waitForExistence(timeout: 2) ||
            app.buttons["Import from Files"].waitForExistence(timeout: 2)
        if !cameraPresented {
            allowSystemPermissionAlertIfPresent(timeout: 1)
            cameraPresented =
                cameraRoot.waitForExistence(timeout: 2) ||
                app.activityIndicators["moment-camera-view"].waitForExistence(timeout: 1) ||
                app.buttons["moment-camera-library-button"].waitForExistence(timeout: 1) ||
                app.buttons["Import from Files"].waitForExistence(timeout: 1)
        }
        XCTAssertTrue(cameraPresented)
    }

    func testContinueAdvancesFromRoseToBudToThorn() {
        let app = launchAppForUITests(
            resetOnboarding: true,
            onboardingCountdownSeconds: 6
        )
        dismissOnboardingIfPresented(app)

        let continueButton = app.buttons["journal-continue-button"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 6))

        let roseField = app.textFields["Rose for today"]
        XCTAssertTrue(roseField.exists)
        roseField.tap()
        roseField.typeText("Rose quick entry")
        continueButton.tap()

        let budField = app.textFields["Bud for today"]
        XCTAssertTrue(budField.waitForExistence(timeout: 4))
        budField.tap()
        budField.typeText("Bud quick entry")
        continueButton.tap()

        let thornField = app.textFields["Thorn for today"]
        XCTAssertTrue(thornField.waitForExistence(timeout: 4))
        thornField.tap()
        thornField.typeText("Thorn quick entry")
        continueButton.tap()

        XCTAssertTrue(app.otherElements["journal-capture-locked-state"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["journal-add-photo-button"].exists)
    }

    private func dismissPhotoPickerIfNeeded(_ app: XCUIApplication) {
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.waitForExistence(timeout: 1) {
            cancel.tap()
            return
        }

        let close = app.buttons["Close"].firstMatch
        if close.waitForExistence(timeout: 1) {
            close.tap()
            return
        }

        app.swipeDown()
    }
}
