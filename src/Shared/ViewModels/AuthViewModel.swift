//
//  AuthViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/25/21.
//

import Foundation
import AuthenticationServices

class AuthViewModel: ObservableObject {
    
    private let defaults = UserDefaults.standard
    private let facebookAuthService = FacebookAuthService()

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
            let userData = try await facebookAuthService.loginWithFacebook()
            
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
            facebookAuthService.clearStoredToken()
            
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}
