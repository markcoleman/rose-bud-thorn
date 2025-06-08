//
//  FacebookAuthTests.swift
//  rose.bud.thorn
//
//  Created by Copilot for Facebook authentication testing
//

import XCTest
@testable import RoseBudThorn

class FacebookAuthTests: XCTestCase {
    
    var authViewModel: AuthViewModel!
    var profileModel: ProfileModel!
    
    override func setUpWithError() throws {
        profileModel = ProfileModel()
        authViewModel = AuthViewModel(model: profileModel)
    }
    
    override func tearDownWithError() throws {
        // Clear any stored data after each test
        authViewModel.signOut()
        authViewModel = nil
        profileModel = nil
    }
    
    // MARK: - AuthViewModel Tests
    
    func testInitialSignedInState() {
        // Given a new AuthViewModel
        // When checking initial state
        // Then user should not be signed in
        XCTAssertFalse(authViewModel.isSignedIn)
        XCTAssertNil(authViewModel.model.facebookAccessToken)
        XCTAssertNil(authViewModel.model.identityToken)
    }
    
    func testSignedInStateWithFacebookToken() {
        // Given an AuthViewModel
        // When Facebook token is set
        authViewModel.model.facebookAccessToken = "test_facebook_token"
        
        // Then user should be signed in
        XCTAssertTrue(authViewModel.isSignedIn)
    }
    
    func testSignedInStateWithAppleToken() {
        // Given an AuthViewModel
        // When Apple identity token is set
        authViewModel.model.identityToken = Data("test_apple_token".utf8)
        
        // Then user should be signed in
        XCTAssertTrue(authViewModel.isSignedIn)
    }
    
    func testSignOutClearsAllData() {
        // Given an AuthViewModel with both Facebook and Apple data
        authViewModel.model.facebookAccessToken = "test_facebook_token"
        authViewModel.model.facebookUserId = "test_user_id"
        authViewModel.model.identityToken = Data("test_apple_token".utf8)
        authViewModel.model.email = "test@example.com"
        authViewModel.model.givenName = "Test"
        authViewModel.model.familyName = "User"
        authViewModel.model.authProvider = "facebook"
        authViewModel.model.profilePictureURL = "https://example.com/pic.jpg"
        
        // When signing out
        authViewModel.signOut()
        
        // Then all data should be cleared
        XCTAssertFalse(authViewModel.isSignedIn)
        XCTAssertNil(authViewModel.model.facebookAccessToken)
        XCTAssertNil(authViewModel.model.facebookUserId)
        XCTAssertNil(authViewModel.model.identityToken)
        XCTAssertNil(authViewModel.model.email)
        XCTAssertNil(authViewModel.model.givenName)
        XCTAssertNil(authViewModel.model.familyName)
        XCTAssertNil(authViewModel.model.authProvider)
        XCTAssertNil(authViewModel.model.profilePictureURL)
    }
    
    // MARK: - ProfileModel Tests
    
    func testProfileModelFacebookProperties() {
        // Given a ProfileModel
        let model = ProfileModel()
        
        // When setting Facebook properties
        model.facebookAccessToken = "test_token"
        model.facebookUserId = "test_user_id"
        model.profilePictureURL = "https://example.com/pic.jpg"
        model.authProvider = "facebook"
        
        // Then properties should be stored and retrieved correctly
        XCTAssertEqual(model.facebookAccessToken, "test_token")
        XCTAssertEqual(model.facebookUserId, "test_user_id")
        XCTAssertEqual(model.profilePictureURL, "https://example.com/pic.jpg")
        XCTAssertEqual(model.authProvider, "facebook")
    }
    
    func testProfileModelAppleProperties() {
        // Given a ProfileModel
        let model = ProfileModel()
        
        // When setting Apple properties
        model.identityToken = Data("test_token".utf8)
        model.userId = "test_apple_user_id"
        model.authProvider = "apple"
        
        // Then properties should be stored and retrieved correctly
        XCTAssertEqual(model.identityToken, Data("test_token".utf8))
        XCTAssertEqual(model.userId, "test_apple_user_id")
        XCTAssertEqual(model.authProvider, "apple")
    }
    
    // MARK: - FacebookUserData Tests
    
    func testFacebookUserDataNameParsing() {
        // Given a FacebookUserData with a full name
        let userData = FacebookUserData(
            id: "123",
            name: "John Doe",
            email: "john@example.com",
            profilePictureURL: "https://example.com/pic.jpg",
            accessToken: "token"
        )
        
        // When accessing parsed name components
        // Then given and family names should be correctly parsed
        XCTAssertEqual(userData.givenName, "John")
        XCTAssertEqual(userData.familyName, "Doe")
    }
    
    func testFacebookUserDataSingleNameParsing() {
        // Given a FacebookUserData with a single name
        let userData = FacebookUserData(
            id: "123",
            name: "John",
            email: "john@example.com",
            profilePictureURL: "https://example.com/pic.jpg",
            accessToken: "token"
        )
        
        // When accessing parsed name components
        // Then given name should be set and family name should be nil
        XCTAssertEqual(userData.givenName, "John")
        XCTAssertNil(userData.familyName)
    }
    
    func testFacebookUserDataMultipleNameParsing() {
        // Given a FacebookUserData with multiple names
        let userData = FacebookUserData(
            id: "123",
            name: "John Michael Doe Jr",
            email: "john@example.com",
            profilePictureURL: "https://example.com/pic.jpg",
            accessToken: "token"
        )
        
        // When accessing parsed name components
        // Then given name should be first and family name should be rest
        XCTAssertEqual(userData.givenName, "John")
        XCTAssertEqual(userData.familyName, "Michael Doe Jr")
    }
    
    // MARK: - Error Handling Tests
    
    func testFacebookAuthErrorDescriptions() {
        // Test error message descriptions
        XCTAssertEqual(
            FacebookAuthError.loginCanceled.errorDescription,
            "Facebook login was canceled or failed. Please try again."
        )
        
        XCTAssertEqual(
            FacebookAuthError.noAccessToken.errorDescription,
            "Failed to obtain Facebook access token."
        )
        
        XCTAssertEqual(
            FacebookAuthError.loginFailed("Network error").errorDescription,
            "Facebook login failed: Network error"
        )
        
        XCTAssertEqual(
            FacebookAuthError.profileFetchFailed.errorDescription,
            "Failed to fetch user profile from Facebook."
        )
    }
}