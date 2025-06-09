//
//  ProfileViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/24/21.
//

import Foundation
import RoseBudThornCore

class ProfileViewModel: ObservableObject {
    
    @Published var model: ProfileModel
    init(model: ProfileModel){
        self.model = model
    }
    
    var isSignedIn: Bool{
        model.identityToken != nil
    }
    
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
            
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}
