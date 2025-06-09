//
//  GoogleSignInUITests.swift
//  rose.bud.thorn UI Tests
//
//  Created by Copilot for Google Sign-In UI testing
//

import XCTest

#if canImport(XCTest) && (os(iOS) || os(macOS) || os(macCatalyst) || os(tvOS) || os(watchOS) || os(visionOS))

class GoogleSignInUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testGoogleSignInButtonAppearance() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify Google Sign-In button is present and accessible
        let googleSignInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(googleSignInButton.exists, "Google Sign-In button should be visible")
        XCTAssertTrue(googleSignInButton.isEnabled, "Google Sign-In button should be enabled")
        
        // Verify accessibility
        XCTAssertEqual(googleSignInButton.label, "Sign in with Google")
        XCTAssertFalse(googleSignInButton.label.isEmpty, "Button should have accessibility label")
        
        // Verify button positioning relative to Facebook button
        let facebookButton = app.buttons["Continue with Facebook"]
        XCTAssertTrue(facebookButton.exists, "Facebook button should exist")
        
        // Google button should be below Facebook button
        XCTAssertLessThan(facebookButton.frame.maxY, googleSignInButton.frame.minY, 
                         "Google button should be positioned below Facebook button")
    }

    func testGoogleSignInFlow() throws {
        let app = XCUIApplication()
        app.launch()

        let googleSignInButton = app.buttons["Sign in with Google"]
        XCTAssertTrue(googleSignInButton.waitForExistence(timeout: 5))
        
        // Tap Google Sign-In button
        googleSignInButton.tap()
        
        // Note: In a real UI test, you would need to handle the OAuth web view
        // and simulate user interaction with Google's authentication interface.
        // This would typically involve:
        // 1. Waiting for Safari/web view to appear
        // 2. Interacting with Google's sign-in form
        // 3. Handling the redirect back to the app
        // 4. Verifying successful authentication
        
        // For testing purposes without live OAuth, you could:
        // - Mock the OAuth response
        // - Use a test Google account
        // - Stub the authentication flow
    }

    func testGoogleSignInErrorHandling() throws {
        let app = XCUIApplication()
        
        // Configure app to simulate error conditions
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--simulate-google-auth-error")
        app.launch()

        let googleSignInButton = app.buttons["Sign in with Google"]
        googleSignInButton.tap()
        
        // Verify error message appears
        let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Google sign-in failed'"))
        XCTAssertTrue(errorText.element.waitForExistence(timeout: 3), 
                     "Error message should appear when sign-in fails")
    }

    func testGoogleSignInCancellation() throws {
        let app = XCUIApplication()
        
        // Configure app to simulate user cancellation
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--simulate-google-auth-cancel")
        app.launch()

        let googleSignInButton = app.buttons["Sign in with Google"]
        googleSignInButton.tap()
        
        // Verify appropriate cancellation message
        let cancelMessage = app.staticTexts["Google sign-in failed or was canceled. Please try again."]
        XCTAssertTrue(cancelMessage.waitForExistence(timeout: 3), 
                     "Cancellation message should appear when user cancels")
    }

    func testGoogleSignInLoadingState() throws {
        let app = XCUIApplication()
        
        // Configure app to simulate loading state
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--simulate-google-auth-loading")
        app.launch()

        let googleSignInButton = app.buttons["Sign in with Google"]
        googleSignInButton.tap()
        
        // Verify button shows loading state
        XCTAssertFalse(googleSignInButton.isEnabled, "Button should be disabled during loading")
        
        // Look for progress indicator
        let progressIndicator = app.activityIndicators.firstMatch
        XCTAssertTrue(progressIndicator.exists, "Progress indicator should be visible during loading")
    }

    func testAccessibilityLabels() throws {
        let app = XCUIApplication()
        app.launch()
        
        let googleSignInButton = app.buttons["Sign in with Google"]
        
        // Test accessibility properties
        XCTAssertEqual(googleSignInButton.label, "Sign in with Google")
        XCTAssertTrue(googleSignInButton.isHittable, "Button should be accessible to assistive technologies")
        
        // Verify button meets minimum touch target size (44pt)
        let buttonFrame = googleSignInButton.frame
        XCTAssertGreaterThanOrEqual(buttonFrame.height, 44, "Button height should meet accessibility guidelines")
        XCTAssertGreaterThanOrEqual(buttonFrame.width, 44, "Button width should meet accessibility guidelines")
    }

    func testVoiceOverSupport() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Enable VoiceOver simulation
        let googleSignInButton = app.buttons["Sign in with Google"]
        
        // Verify VoiceOver can access the button
        XCTAssertTrue(googleSignInButton.isAccessibilityElement, 
                     "Button should be accessible to VoiceOver")
        
        // Test that accessibility hint provides context
        // Note: Accessibility hints are read by VoiceOver to provide additional context
        // The hint should explain what the button does
    }
}

// MARK: - Test Configuration Extensions

extension XCUIApplication {
    var isUITesting: Bool {
        launchArguments.contains("--ui-testing")
    }
    
    var shouldSimulateGoogleAuthError: Bool {
        launchArguments.contains("--simulate-google-auth-error")
    }
    
    var shouldSimulateGoogleAuthCancel: Bool {
        launchArguments.contains("--simulate-google-auth-cancel")
    }
    
    var shouldSimulateGoogleAuthLoading: Bool {
        launchArguments.contains("--simulate-google-auth-loading")
    }
}

#endif