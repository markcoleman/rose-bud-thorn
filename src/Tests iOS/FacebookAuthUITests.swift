//
//  FacebookAuthUITests.swift
//  rose.bud.thorn
//
//  Created by Copilot for Facebook authentication UI testing
//

import XCTest

class FacebookAuthUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testFacebookButtonExists() throws {
        // Given the app is launched
        // When the splash screen is displayed
        // Then the Facebook login button should be visible
        let facebookButton = app.buttons["Continue with Facebook"]
        XCTAssertTrue(facebookButton.exists, "Facebook login button should exist on splash screen")
        XCTAssertTrue(facebookButton.isHittable, "Facebook login button should be tappable")
    }
    
    func testFacebookButtonAccessibility() throws {
        // Given the app is launched
        // When checking the Facebook button accessibility
        let facebookButton = app.buttons["Continue with Facebook"]
        
        // Then the button should have proper accessibility properties
        XCTAssertTrue(facebookButton.exists)
        XCTAssertEqual(facebookButton.label, "Continue with Facebook")
        
        // Check if accessibility hint is available (note: hints may not always be exposed in UI tests)
        if !facebookButton.value.description.isEmpty {
            XCTAssertTrue(facebookButton.value.description.contains("Facebook") || facebookButton.value.description.contains("credentials"))
        }
    }
    
    func testFacebookButtonTap() throws {
        // Given the app is launched and the Facebook button is visible
        let facebookButton = app.buttons["Continue with Facebook"]
        XCTAssertTrue(facebookButton.waitForExistence(timeout: 5))
        
        // When tapping the Facebook button
        facebookButton.tap()
        
        // Then the button should respond (we can't test actual Facebook login in UI tests without mocking)
        // We can verify the button was tapped by checking if it temporarily becomes disabled
        // or if a loading state appears
        
        // Note: In a real implementation, this would trigger ASWebAuthenticationSession
        // which would open a web view. In automated tests, this needs to be mocked.
    }
    
    func testAppleSignInButtonStillExists() throws {
        // Given the app is launched
        // When checking for the Apple Sign-In button
        let appleButton = app.buttons["Sign in with Apple"]
        
        // Then the Apple Sign-In button should still be present alongside Facebook
        XCTAssertTrue(appleButton.exists, "Apple Sign-In button should still exist alongside Facebook button")
        XCTAssertTrue(appleButton.isHittable, "Apple Sign-In button should still be tappable")
    }
    
    func testBothAuthButtonsAreVisible() throws {
        // Given the app is launched
        // When the splash screen is displayed
        let appleButton = app.buttons["Sign in with Apple"]
        let facebookButton = app.buttons["Continue with Facebook"]
        
        // Then both authentication buttons should be visible
        XCTAssertTrue(appleButton.exists, "Apple Sign-In button should be visible")
        XCTAssertTrue(facebookButton.exists, "Facebook login button should be visible")
        
        // And both should be in the viewport
        XCTAssertTrue(appleButton.isHittable, "Apple button should be hittable")
        XCTAssertTrue(facebookButton.isHittable, "Facebook button should be hittable")
    }
    
    func testPrivacyNoticeIsVisible() throws {
        // Given the app is launched
        // When checking for the privacy notice
        let privacyNotice = app.staticTexts["We'll never post to Facebook without your permission."]
        
        // Then the privacy notice should be visible below the Facebook button
        XCTAssertTrue(privacyNotice.waitForExistence(timeout: 5), "Privacy notice should be visible")
    }
    
    func testAppLogoIsAccessible() throws {
        // Given the app is launched
        // When checking the app logo accessibility
        let appLogo = app.staticTexts["Rose Bud Thorn app logo"]
        
        // Then the logo should have proper accessibility labeling
        XCTAssertTrue(appLogo.exists, "App logo should have accessibility label")
    }
    
    func testLaunchScreenshot() throws {
        // Given the app is launched
        // When taking a screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen with Facebook Login"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // This helps with visual regression testing
        // Verify that both login buttons are visible in the screenshot
        let appleButton = app.buttons["Sign in with Apple"]
        let facebookButton = app.buttons["Continue with Facebook"]
        
        XCTAssertTrue(appleButton.exists)
        XCTAssertTrue(facebookButton.exists)
    }
}