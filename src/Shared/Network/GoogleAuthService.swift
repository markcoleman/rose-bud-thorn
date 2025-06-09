//
//  GoogleAuthService.swift
//  rose.bud.thorn
//
//  Created by Copilot for Google Sign-In integration
//

import Foundation

#if canImport(GoogleSignIn) && canImport(UIKit)
import GoogleSignIn
import UIKit
#endif

// MARK: - Google Auth Service Protocol

protocol GoogleAuthService {
    func signIn() async throws -> GoogleUserData
    func signOut() throws
    func configure()
}

// MARK: - Google User Data Model

struct GoogleUserData {
    let id: String
    let email: String?
    let givenName: String?
    let familyName: String?
    let profilePictureURL: String?
    let accessToken: String?
    let idToken: String?
}

// MARK: - Default Implementation

#if canImport(GoogleSignIn) && canImport(UIKit)
class DefaultGoogleAuthService: GoogleAuthService {
    
    func configure() {
        guard let configPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let config = GIDConfiguration(contentsOfFile: configPath) else {
            print("Warning: GoogleService-Info.plist not found. Google Sign-In will not work properly.")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = config
    }
    
    func signIn() async throws -> GoogleUserData {
        guard let presentingViewController = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first?.rootViewController else {
            throw GoogleAuthError.noPresentingViewController
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    if let gidError = error as? GIDSignInError,
                       gidError.code == .canceled {
                        continuation.resume(throwing: GoogleAuthError.signInCanceled)
                    } else {
                        continuation.resume(throwing: GoogleAuthError.signInFailed(error.localizedDescription))
                    }
                    return
                }
                
                guard let result = result,
                      let user = result.user.profile else {
                    continuation.resume(throwing: GoogleAuthError.noUserProfile)
                    return
                }
                
                let userData = GoogleUserData(
                    id: result.user.userID ?? "",
                    email: user.email,
                    givenName: user.givenName,
                    familyName: user.familyName,
                    profilePictureURL: user.imageURL(withDimension: 120)?.absoluteString,
                    accessToken: result.user.accessToken.tokenString,
                    idToken: result.user.idToken?.tokenString
                )
                
                continuation.resume(returning: userData)
            }
        }
    }
    
    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
    }
}
#else
// Fallback implementation for platforms that don't support GoogleSignIn
class DefaultGoogleAuthService: GoogleAuthService {
    func configure() {
        print("Google Sign-In not available on this platform")
    }
    
    func signIn() async throws -> GoogleUserData {
        throw GoogleAuthError.signInFailed("Google Sign-In not available on this platform")
    }
    
    func signOut() throws {
        // No-op for unsupported platforms
    }
}
#endif

// MARK: - Mock Implementation for Testing

class MockGoogleAuthService: GoogleAuthService {
    var shouldSucceed = true
    var mockUserData: GoogleUserData?
    var configureCallCount = 0
    var signInCallCount = 0
    var signOutCallCount = 0
    
    func configure() {
        configureCallCount += 1
    }
    
    func signIn() async throws -> GoogleUserData {
        signInCallCount += 1
        
        if shouldSucceed {
            return mockUserData ?? GoogleUserData(
                id: "mock_google_user_id",
                email: "mock@google.com",
                givenName: "Mock",
                familyName: "User",
                profilePictureURL: "https://example.com/profile.jpg",
                accessToken: "mock_access_token",
                idToken: "mock_id_token"
            )
        } else {
            throw GoogleAuthError.signInFailed("Mock error")
        }
    }
    
    func signOut() throws {
        signOutCallCount += 1
    }
}

// MARK: - Error Handling

enum GoogleAuthError: LocalizedError {
    case signInCanceled
    case signInFailed(String)
    case noUserProfile
    case noPresentingViewController
    
    var errorDescription: String? {
        switch self {
        case .signInCanceled:
            return "Google sign-in failed or was canceled. Please try again."
        case .signInFailed(let message):
            return "Google sign-in failed: \(message)"
        case .noUserProfile:
            return "Failed to retrieve user profile from Google."
        case .noPresentingViewController:
            return "Unable to present Google sign-in interface."
        }
    }
}