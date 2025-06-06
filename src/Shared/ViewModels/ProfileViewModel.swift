//
//  ProfileViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/24/21.
//

import Foundation

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
            self.model.userId = nil
            self.model.identityToken = nil
            self.model.authCode = nil
            self.model.email = nil
            self.model.givenName = nil
            self.model.familyName = nil
            self.model.state = nil
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}
