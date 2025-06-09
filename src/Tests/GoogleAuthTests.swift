//
//  GoogleAuthTests.swift
//  rose.bud.thorn
//
//  Created by Copilot for Google Sign-In testing
//

import XCTest
@testable import RoseBudThornCore

#if canImport(SwiftUI) && (os(iOS) || os(macOS) || os(macCatalyst) || os(tvOS) || os(watchOS) || os(visionOS))
@testable import RoseBudThornUI

class GoogleAuthTests: XCTestCase {
    
    var authViewModel: AuthViewModel!
    var mockGoogleService: MockGoogleAuthService!
    var profileModel: ProfileModel!
    
    override func setUp() {
        super.setUp()
        profileModel = ProfileModel()
        mockGoogleService = MockGoogleAuthService()
        authViewModel = AuthViewModel(model: profileModel, googleAuthService: mockGoogleService)
    }
    
    override func tearDown() {
        authViewModel = nil
        mockGoogleService = nil
        profileModel = nil
        super.tearDown()
    }
    
    func testGoogleAuthServiceConfiguration() {
        // Test that GoogleAuthService is configured on initialization
        XCTAssertEqual(mockGoogleService.configureCallCount, 1, "GoogleAuthService should be configured during AuthViewModel initialization")
    }
    
    func testSuccessfulGoogleSignIn() async {
        // Given
        let expectedUserData = GoogleUserData(
            id: "test_google_id",
            email: "test@google.com",
            givenName: "Test",
            familyName: "User",
            profilePictureURL: "https://example.com/profile.jpg",
            accessToken: "test_access_token",
            idToken: "test_id_token"
        )
        mockGoogleService.mockUserData = expectedUserData
        mockGoogleService.shouldSucceed = true
        
        // When
        await authViewModel.loginWithGoogle()
        
        // Then
        XCTAssertEqual(mockGoogleService.signInCallCount, 1, "Sign in should be called once")
        XCTAssertEqual(authViewModel.model.googleUserId, expectedUserData.id)
        XCTAssertEqual(authViewModel.model.email, expectedUserData.email)
        XCTAssertEqual(authViewModel.model.givenName, expectedUserData.givenName)
        XCTAssertEqual(authViewModel.model.familyName, expectedUserData.familyName)
        XCTAssertEqual(authViewModel.model.profilePictureURL, expectedUserData.profilePictureURL)
        XCTAssertEqual(authViewModel.model.authProvider, "google")
        XCTAssertEqual(authViewModel.model.googleAccessToken, expectedUserData.accessToken)
        XCTAssertEqual(authViewModel.model.googleIdToken, expectedUserData.idToken)
        XCTAssertFalse(authViewModel.isLoading, "Loading should be false after completion")
        XCTAssertNil(authViewModel.errorMessage, "Error message should be nil on success")
    }
    
    func testFailedGoogleSignIn() async {
        // Given
        mockGoogleService.shouldSucceed = false
        
        // When
        await authViewModel.loginWithGoogle()
        
        // Then
        XCTAssertEqual(mockGoogleService.signInCallCount, 1, "Sign in should be called once")
        XCTAssertNil(authViewModel.model.googleUserId, "Google user ID should be nil on failure")
        XCTAssertNotEqual(authViewModel.model.authProvider, "google", "Auth provider should not be set to google on failure")
        XCTAssertFalse(authViewModel.isLoading, "Loading should be false after completion")
        XCTAssertNotNil(authViewModel.errorMessage, "Error message should be present on failure")
        XCTAssertEqual(authViewModel.errorMessage, "Google sign-in failed: Mock error")
    }
    
    func testIsSignedInWithGoogleAuth() {
        // Given - user not signed in initially
        XCTAssertFalse(authViewModel.isSignedIn, "User should not be signed in initially")
        
        // When - set Google access token
        authViewModel.model.googleAccessToken = "test_token"
        
        // Then
        XCTAssertTrue(authViewModel.isSignedIn, "User should be signed in with Google token")
    }
    
    func testSignOutClearsGoogleData() {
        // Given - user signed in with Google
        authViewModel.model.googleUserId = "test_id"
        authViewModel.model.googleAccessToken = "test_token"
        authViewModel.model.googleIdToken = "test_id_token"
        authViewModel.model.email = "test@google.com"
        authViewModel.model.authProvider = "google"
        
        // When
        authViewModel.signOut()
        
        // Then
        XCTAssertNil(authViewModel.model.googleUserId, "Google user ID should be cleared")
        XCTAssertNil(authViewModel.model.googleAccessToken, "Google access token should be cleared")
        XCTAssertNil(authViewModel.model.googleIdToken, "Google ID token should be cleared")
        XCTAssertNil(authViewModel.model.email, "Email should be cleared")
        XCTAssertNil(authViewModel.model.authProvider, "Auth provider should be cleared")
        XCTAssertEqual(mockGoogleService.signOutCallCount, 1, "Google service sign out should be called")
    }
    
    func testGoogleUserDataModel() {
        // Test GoogleUserData initialization and properties
        let userData = GoogleUserData(
            id: "123",
            email: "test@example.com",
            givenName: "John",
            familyName: "Doe",
            profilePictureURL: "https://example.com/pic.jpg",
            accessToken: "access_token",
            idToken: "id_token"
        )
        
        XCTAssertEqual(userData.id, "123")
        XCTAssertEqual(userData.email, "test@example.com")
        XCTAssertEqual(userData.givenName, "John")
        XCTAssertEqual(userData.familyName, "Doe")
        XCTAssertEqual(userData.profilePictureURL, "https://example.com/pic.jpg")
        XCTAssertEqual(userData.accessToken, "access_token")
        XCTAssertEqual(userData.idToken, "id_token")
    }
    
    func testGoogleAuthErrorLocalizedDescriptions() {
        // Test error message localization
        XCTAssertEqual(
            GoogleAuthError.signInCanceled.errorDescription,
            "Google sign-in failed or was canceled. Please try again."
        )
        
        XCTAssertEqual(
            GoogleAuthError.signInFailed("Custom error").errorDescription,
            "Google sign-in failed: Custom error"
        )
        
        XCTAssertEqual(
            GoogleAuthError.noUserProfile.errorDescription,
            "Failed to retrieve user profile from Google."
        )
        
        XCTAssertEqual(
            GoogleAuthError.noPresentingViewController.errorDescription,
            "Unable to present Google sign-in interface."
        )
    }
}

#endif