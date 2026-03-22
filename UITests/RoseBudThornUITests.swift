import XCTest

final class RoseBudThornUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFirstLaunchShowsOnboardingThenSkipOpensToday() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 20)

        let skipButton = app.buttons["onboarding-skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 4))
        XCTAssertTrue(skipButton.isHittable)
        skipButton.tap()

        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 6))
    }

    func testOnboardingSwipeUpdatesPageIndicator() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 8)

        let indicator = element(withIdentifier: "onboarding-page-indicator", in: app)
        XCTAssertTrue(indicator.waitForExistence(timeout: 4))
        XCTAssertEqual(indicator.label, "Page 1 of 3")

        app.swipeLeft()
        expectation(for: NSPredicate(format: "label == %@", "Page 2 of 3"), evaluatedWith: indicator)
        waitForExpectations(timeout: 4)
    }

    func testOnboardingCountdownAutoAdvances() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 2)

        let indicator = element(withIdentifier: "onboarding-page-indicator", in: app)
        XCTAssertTrue(indicator.waitForExistence(timeout: 4))
        expectation(for: NSPredicate(format: "label == %@", "Page 2 of 3"), evaluatedWith: indicator)
        waitForExpectations(timeout: 6)
    }

    func testOnboardingLastScreenCanCloseWithX() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 8)

        XCTAssertTrue(app.buttons["onboarding-next"].waitForExistence(timeout: 4))
        app.buttons["onboarding-next"].tap()
        XCTAssertTrue(app.buttons["onboarding-next"].waitForExistence(timeout: 4))
        app.buttons["onboarding-next"].tap()

        let closeButton = app.buttons["onboarding-close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 4))
        closeButton.tap()

        XCTAssertTrue(app.textFields["Rose for today"].waitForExistence(timeout: 6))
    }

    func testSettingsReplayOnboardingReopensFlow() {
        let app = launchAppForUITests(resetOnboarding: true, onboardingCountdownSeconds: 6)
        dismissOnboardingIfPresented(app)

        tapTabBarButton(titled: "Insights", in: app)

        let moreButton = app.buttons["insights-more-button"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 6))
        moreButton.tap()
        app.buttons["insights-more-settings"].tap()

        let replayButton = app.buttons["settings-replay-onboarding"].firstMatch
        if !replayButton.waitForExistence(timeout: 2) || !replayButton.isHittable {
            _ = scrollToElement(replayButton, in: app)
        }
        XCTAssertTrue(replayButton.exists)
        replayButton.tap()

        XCTAssertTrue(element(withIdentifier: "onboarding-page-indicator", in: app).waitForExistence(timeout: 4))
    }

    func testCaptureAppStoreScreenshots() {
        let app = launchAppForUITests(
            resetOnboarding: true,
            onboardingCountdownSeconds: 120,
            seedJournalData: true
        )

        XCTAssertTrue(element(withIdentifier: "onboarding-page-indicator", in: app).waitForExistence(timeout: 6))
        captureScreenshot(named: "01-onboarding-hero")

        dismissOnboardingIfPresented(app)
        let journalLoaded =
            app.textFields["Rose for today"].waitForExistence(timeout: 10) ||
            element(withIdentifier: "journal-active-prompt", in: app).waitForExistence(timeout: 2) ||
            app.buttons["journal-continue-button"].waitForExistence(timeout: 2)
        XCTAssertTrue(journalLoaded)
        captureScreenshot(named: "02-today-capture")

        app.swipeUp()
        captureScreenshot(named: "03-journal-timeline")

        var didOpenDayDetail = false
        let openTodayDetail = app.buttons["journal-open-today-detail-button"].firstMatch
        if openTodayDetail.waitForExistence(timeout: 3) {
            openTodayDetail.tap()
            didOpenDayDetail = dayPolaroidPager(in: app, timeout: 4).exists
        } else {
            let dayCard = journalDayCardButton(in: app, timeout: 2)
            if dayCard.exists {
                dayCard.tap()
                didOpenDayDetail = dayPolaroidPager(in: app, timeout: 4).exists
            }
        }
        captureScreenshot(named: "04-day-detail")

        if didOpenDayDetail {
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.waitForExistence(timeout: 3) {
                backButton.tap()
            }
        }

        let insightsCandidates: [XCUIElement] = [
            app.buttons["floating-tab-insights"].firstMatch,
            app.buttons.matching(NSPredicate(format: "label == %@", "Insights")).firstMatch,
            app.staticTexts["Insights"].firstMatch,
        ]
        for candidate in insightsCandidates {
            guard candidate.waitForExistence(timeout: 2), candidate.isHittable else { continue }
            candidate.tap()
            break
        }
        _ = app.navigationBars["Insights"].waitForExistence(timeout: 4)
        captureScreenshot(named: "05-insights")
    }

    private func captureScreenshot(named name: String) {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
