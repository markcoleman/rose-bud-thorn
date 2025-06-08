//
//  FacebookAuthService.swift
//  rose.bud.thorn
//
//  Created by Copilot for Facebook Social Login support
//

import Foundation
import AuthenticationServices
import FacebookLogin
import KeychainAccess

@MainActor
class FacebookAuthService: NSObject, ObservableObject {
    
    private let keychain = Keychain(service: "com.eweandme.rose-bud-thorn.facebook")
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Facebook Login
    
    func loginWithFacebook() async throws -> FacebookUserData {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        // Use ASWebAuthenticationSession for OAuth flow as per requirements
        let loginManager = LoginManager()
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result in
                    continuation.resume(with: result)
                }
            }
            
            guard let token = result?.token else {
                throw FacebookAuthError.noAccessToken
            }
            
            // Store token securely in keychain
            try keychain.set(token.tokenString, key: "access_token")
            
            // Fetch user profile data
            let userData = try await fetchUserProfile(token: token.tokenString)
            
            return userData
            
        } catch {
            if let fbError = error as? FacebookAuthError {
                throw fbError
            } else {
                throw FacebookAuthError.loginFailed(error.localizedDescription)
            }
        }
    }
    
    // MARK: - User Profile Fetching
    
    private func fetchUserProfile(token: String) async throws -> FacebookUserData {
        let url = URL(string: "https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token=\(token)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FacebookAuthError.profileFetchFailed
        }
        
        let decoder = JSONDecoder()
        let profileResponse = try decoder.decode(FacebookProfileResponse.self, from: data)
        
        return FacebookUserData(
            id: profileResponse.id,
            name: profileResponse.name,
            email: profileResponse.email,
            profilePictureURL: profileResponse.picture.data.url,
            accessToken: token
        )
    }
    
    // MARK: - Token Management
    
    func getStoredAccessToken() -> String? {
        return try? keychain.get("access_token")
    }
    
    func clearStoredToken() {
        try? keychain.remove("access_token")
    }
    
    func isLoggedIn() -> Bool {
        return getStoredAccessToken() != nil && AccessToken.current != nil
    }
}

// MARK: - Data Models

struct FacebookUserData {
    let id: String
    let name: String
    let email: String?
    let profilePictureURL: String?
    let accessToken: String
    
    var givenName: String? {
        return name.components(separatedBy: " ").first
    }
    
    var familyName: String? {
        let components = name.components(separatedBy: " ")
        return components.count > 1 ? components.dropFirst().joined(separator: " ") : nil
    }
}

private struct FacebookProfileResponse: Codable {
    let id: String
    let name: String
    let email: String?
    let picture: FacebookPicture
}

private struct FacebookPicture: Codable {
    let data: FacebookPictureData
}

private struct FacebookPictureData: Codable {
    let url: String
}

// MARK: - Error Handling

enum FacebookAuthError: LocalizedError {
    case loginCanceled
    case noAccessToken
    case loginFailed(String)
    case profileFetchFailed
    
    var errorDescription: String? {
        switch self {
        case .loginCanceled:
            return "Facebook login was canceled or failed. Please try again."
        case .noAccessToken:
            return "Failed to obtain Facebook access token."
        case .loginFailed(let message):
            return "Facebook login failed: \(message)"
        case .profileFetchFailed:
            return "Failed to fetch user profile from Facebook."
        }
    }
}