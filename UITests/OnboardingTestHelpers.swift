import XCTest

extension XCTestCase {
    @discardableResult
    func launchAppForUITests(
        resetOnboarding: Bool = false,
        onboardingCountdownSeconds: Int? = nil,
        seedJournalData: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        if resetOnboarding {
            app.launchArguments.append("-reset-onboarding")
        }
        if seedJournalData {
            app.launchArguments.append("-seed-journal-ui-data")
        }
        if let onboardingCountdownSeconds {
            app.launchArguments.append("-onboarding-countdown-seconds")
            app.launchArguments.append(String(onboardingCountdownSeconds))
        }
        app.launch()
        return app
    }

    func dismissOnboardingIfPresented(_ app: XCUIApplication, timeout: TimeInterval = 2) {
        let skip = app.buttons["onboarding-skip"]
        if skip.waitForExistence(timeout: timeout) {
            skip.tap()
            return
        }

        let close = app.buttons["onboarding-close"]
        if close.waitForExistence(timeout: 0.5) {
            close.tap()
            return
        }

        let start = app.buttons["onboarding-start"]
        if start.waitForExistence(timeout: 0.5) {
            start.tap()
        }
    }

    func tabBarButton(titled title: String, in app: XCUIApplication) -> XCUIElement {
        let normalized = title.lowercased()
        let directIdentifierButton = app.buttons["floating-tab-\(normalized)"].firstMatch
        if directIdentifierButton.exists {
            return directIdentifierButton
        }

        let groupedIdentifierButton = app.buttons
            .matching(identifier: "floating-tab-bar")
            .matching(NSPredicate(format: "label == %@", title))
            .firstMatch
        if groupedIdentifierButton.exists {
            return groupedIdentifierButton
        }

        return app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
    }

    func tapTabBarButton(titled title: String, in app: XCUIApplication, timeout: TimeInterval = 6) {
        let button = tabBarButton(titled: title, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap()
    }

    func journalDayCardButton(in app: XCUIApplication, timeout: TimeInterval = 8) -> XCUIElement {
        let card = app.buttons["journal-day-card"].firstMatch
        if card.waitForExistence(timeout: timeout) {
            return card
        }

        for _ in 0..<3 {
            app.swipeUp()
            if card.waitForExistence(timeout: 1.5) {
                break
            }
        }

        return card
    }

    func element(withIdentifier identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func dayPolaroidPager(in app: XCUIApplication, timeout: TimeInterval = 6) -> XCUIElement {
        let collectionViewPager = app.collectionViews["day-polaroid-pager"].firstMatch
        if collectionViewPager.waitForExistence(timeout: timeout) {
            return collectionViewPager
        }

        let fallbackPager = element(withIdentifier: "day-polaroid-pager", in: app)
        _ = fallbackPager.waitForExistence(timeout: 1)
        return fallbackPager
    }

    func allowSystemPermissionAlertIfPresent(timeout: TimeInterval = 1.5) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else { return }

        let preferredButtons = [
            "Allow",
            "Allow While Using App",
            "Allow Once",
            "OK",
            "Continue",
        ]

        for title in preferredButtons {
            let button = alert.buttons[title]
            if button.exists {
                button.tap()
                return
            }
        }

        let fallbackButton = alert.buttons.element(boundBy: 0)
        if fallbackButton.exists {
            fallbackButton.tap()
        }
    }

    @discardableResult
    func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) -> Bool {
        if element.exists && element.isHittable {
            return true
        }

        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.exists && element.isHittable {
                return true
            }
        }

        for _ in 0..<maxSwipes {
            app.swipeDown()
            if element.exists && element.isHittable {
                return true
            }
        }

        return element.exists && element.isHittable
    }
}
