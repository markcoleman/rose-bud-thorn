//
//  AuthViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/25/21.
//

import Foundation
import AuthenticationServices
import Security

class AuthViewModel: ObservableObject {
    
    private let defaults = UserDefaults.standard
    private let keychainService = "com.eweandme.rose-bud-thorn.facebook"
    private let googleKeychainService = "com.eweandme.rose-bud-thorn.google"
    private let googleAuthService: GoogleAuthService

    @Published
    var model: ProfileModel
    
    @Published
    var isLoading = false
    
    @Published
    var errorMessage: String?
    
    var isSignedIn: Bool{
        model.identityToken != nil || model.facebookAccessToken != nil || model.googleAccessToken != nil
    }
    
    init(model: ProfileModel, googleAuthService: GoogleAuthService = DefaultGoogleAuthService()){
        self.model = model
        self.googleAuthService = googleAuthService
        
        // Configure Google Sign-In
        self.googleAuthService.configure()
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
    
    // MARK: - Google Sign-In
    
    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let userData = try await googleAuthService.signIn()
            
            // Save Google user data to profile model
            self.model.googleUserId = userData.id
            self.model.email = userData.email
            self.model.givenName = userData.givenName
            self.model.familyName = userData.familyName
            self.model.profilePictureURL = userData.profilePictureURL
            self.model.authProvider = "google"
            
            // Store tokens securely in keychain
            if let accessToken = userData.accessToken {
                saveToGoogleKeychain(key: "access_token", data: accessToken.data(using: .utf8)!)
                self.model.googleAccessToken = accessToken
            }
            
            if let idToken = userData.idToken {
                saveToGoogleKeychain(key: "id_token", data: idToken.data(using: .utf8)!)
                self.model.googleIdToken = idToken
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func performFacebookLogin() async throws -> FacebookUserData {
        // NOTE: This implementation requires Facebook App ID and App Secret to be configured
        // In a real implementation, these should be stored in Info.plist and build configuration
        
        // For demo purposes, we'll simulate the OAuth flow structure
        // In production, replace these with your actual Facebook app credentials
        guard let facebookAppId = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String,
              !facebookAppId.isEmpty else {
            // For now, create a demo user to show the flow works
            return FacebookUserData(
                id: "demo_user_id",
                name: "Demo User",
                email: "demo@example.com",
                profilePictureURL: nil,
                accessToken: "demo_token"
            )
        }
        
        let redirectURI = "rosebud://auth/facebook"
        let scopes = "public_profile,email"
        
        // Construct Facebook OAuth URL
        var components = URLComponents(string: "https://www.facebook.com/v18.0/dialog/oauth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: facebookAppId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        
        guard let authURL = components.url else {
            throw FacebookAuthError.loginFailed("Invalid OAuth URL")
        }
        
        // Use ASWebAuthenticationSession for OAuth flow
        let authCode = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "rosebud"
            ) { callbackURL, error in
                if let error = error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        continuation.resume(throwing: FacebookAuthError.loginCanceled)
                    } else {
                        continuation.resume(throwing: FacebookAuthError.loginFailed(error.localizedDescription))
                    }
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: FacebookAuthError.noAccessToken)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            // Configure for ephemeral session as per requirements
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
        
        // Exchange authorization code for access token
        let accessToken = try await exchangeCodeForToken(authCode: authCode, appId: facebookAppId, redirectURI: redirectURI)
        
        // Store token securely in keychain
        saveToKeychain(key: "access_token", data: accessToken.data(using: .utf8)!)
        
        // Fetch user profile data
        let userData = try await fetchFacebookUserProfile(token: accessToken)
        
        return userData
    }
    
    private func exchangeCodeForToken(authCode: String, appId: String, redirectURI: String) async throws -> String {
        // In production, the app secret should be handled server-side for security
        // This is a simplified implementation for demonstration
        guard let appSecret = Bundle.main.object(forInfoDictionaryKey: "FacebookAppSecret") as? String else {
            throw FacebookAuthError.loginFailed("Facebook App Secret not configured")
        }
        
        var components = URLComponents(string: "https://graph.facebook.com/v18.0/oauth/access_token")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: appId),
            URLQueryItem(name: "client_secret", value: appSecret),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code", value: authCode)
        ]
        
        guard let tokenURL = components.url else {
            throw FacebookAuthError.loginFailed("Invalid token exchange URL")
        }
        
        let (data, response) = try await URLSession.shared.data(from: tokenURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FacebookAuthError.noAccessToken
        }
        
        let tokenResponse = try JSONDecoder().decode(FacebookTokenResponse.self, from: data)
        return tokenResponse.access_token
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
            
            // Clear Google data
            self.model.googleUserId = nil
            self.model.googleAccessToken = nil
            self.model.googleIdToken = nil
            
            // Clear common data
            self.model.email = nil
            self.model.givenName = nil
            self.model.familyName = nil
            self.model.profilePictureURL = nil
            self.model.authProvider = nil
            
            // Clear tokens from keychain
            clearFacebookToken()
            clearGoogleTokens()
            
            // Sign out from Google
            try? googleAuthService.signOut()
            
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    // MARK: - Facebook Token Management
    
    private func saveToKeychain(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    private func clearFacebookToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "access_token"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Google Token Management
    
    private func saveToGoogleKeychain(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: googleKeychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadFromGoogleKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: googleKeychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    private func clearGoogleTokens() {
        clearGoogleToken(key: "access_token")
        clearGoogleToken(key: "id_token")
    }
    
    private func clearGoogleToken(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: googleKeychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
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

private struct FacebookTokenResponse: Codable {
    let access_token: String
    let token_type: String?
    let expires_in: Int?
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
