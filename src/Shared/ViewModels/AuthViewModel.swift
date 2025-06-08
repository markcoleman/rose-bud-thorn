//
//  AuthViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/25/21.
//

import Foundation
import AuthenticationServices
import FacebookLogin
import KeychainAccess

class AuthViewModel: ObservableObject {
    
    private let defaults = UserDefaults.standard
    private let keychain = Keychain(service: "com.eweandme.rose-bud-thorn.facebook")

    @Published
    var model: ProfileModel
    
    @Published
    var isLoading = false
    
    @Published
    var errorMessage: String?
    
    var isSignedIn: Bool{
        model.identityToken != nil || model.facebookAccessToken != nil
    }
    
    init(model: ProfileModel){
        self.model = model
    }
    
    // MARK: - Apple Sign-In
    
    func save(appleIDCredential: ASAuthorizationAppleIDCredential){
        let userId = appleIDCredential.user
        let identityToken = appleIDCredential.identityToken
        let authCode = appleIDCredential.authorizationCode
        let email = appleIDCredential.email
        let givenName = appleIDCredential.fullName?.givenName
        let familyName = appleIDCredential.fullName?.familyName
        let state = appleIDCredential.state

        self.model.userId = userId
        self.model.identityToken = identityToken
        self.model.authCode = authCode
        self.model.email = email
        self.model.givenName = givenName
        self.model.familyName = familyName
        self.model.state = state
        self.model.authProvider = "apple"
    }
    
    // MARK: - Facebook Sign-In
    
    func loginWithFacebook() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userData = try await performFacebookLogin()
            
            // Save Facebook user data to profile model
            self.model.facebookUserId = userData.id
            self.model.facebookAccessToken = userData.accessToken
            self.model.email = userData.email
            self.model.givenName = userData.givenName
            self.model.familyName = userData.familyName
            self.model.profilePictureURL = userData.profilePictureURL
            self.model.authProvider = "facebook"
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func performFacebookLogin() async throws -> FacebookUserData {
        // Configure LoginManager to use ASWebAuthenticationSession as per requirements
        let loginManager = LoginManager()
        
        // Set configuration for ephemeral session (prefersEphemeralWebBrowserSession = true)
        if let loginConfiguration = loginManager.configuration {
            // This ensures we don't share cookies between sessions
            loginConfiguration.defaultAudience = .onlyMe
        }
        
        let result = try await withCheckedThrowingContinuation { continuation in
            loginManager.logIn(permissions: ["public_profile", "email"], from: nil) { result in
                continuation.resume(with: result)
            }
        }
        
        // Handle cancellation case
        if result?.isCancelled == true {
            throw FacebookAuthError.loginCanceled
        }
        
        guard let token = result?.token else {
            throw FacebookAuthError.noAccessToken
        }
        
        // Store token securely in keychain
        try keychain.set(token.tokenString, key: "access_token")
        
        // Fetch user profile data
        let userData = try await fetchFacebookUserProfile(token: token.tokenString)
        
        return userData
    }
    
    private func fetchFacebookUserProfile(token: String) async throws -> FacebookUserData {
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
    
    // MARK: - Sign Out
    
    func signOut(){
        if let bundleID = Bundle.main.bundleIdentifier {
            // Clear Apple Sign-In data
            self.model.userId = nil
            self.model.identityToken = nil
            self.model.authCode = nil
            self.model.state = nil
            
            // Clear Facebook data
            self.model.facebookUserId = nil
            self.model.facebookAccessToken = nil
            self.model.profilePictureURL = nil
            
            // Clear common data
            self.model.email = nil
            self.model.givenName = nil
            self.model.familyName = nil
            self.model.authProvider = nil
            
            // Clear Facebook token from keychain
            clearFacebookToken()
            
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    // MARK: - Facebook Token Management
    
    private func clearFacebookToken() {
        try? keychain.remove("access_token")
    }
}

// MARK: - Facebook Data Models

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

// MARK: - Facebook Error Handling

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
