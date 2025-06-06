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

    @Published
    var model: ProfileModel
    
    var isSignedIn: Bool{
        model.identityToken != nil
    }
    
    init(model: ProfileModel){
        self.model = model
    }
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
    }
}
