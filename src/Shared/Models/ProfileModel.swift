//
//  ProfileModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/24/21.
//

import Foundation

struct ProfileModel{
    
    private let defaults = UserDefaults.standard
    
    init(){

    }
    
    var userId: String?{
        get{
            return self.defaults.string(forKey: "userId")
        }
        set(userId){
            defaults.set(userId, forKey: "userId")
        }
    }
    var identityToken: Data?{
        get{
            return self.defaults.data(forKey: "identityToken")
        }
        set(identityToken){
            defaults.set(identityToken, forKey: "identityToken")
        }
    }
    var authCode: Data?{
        get{
            return self.defaults.data(forKey: "authCode")
        }
        set(authCode){
            defaults.set(authCode, forKey: "authCode")
        }
    }
    var email: String?{
        get{
            return self.defaults.string(forKey: "email")
        }
        set(email){
            defaults.set(email, forKey: "email")
        }
    }
    var givenName: String?{
        get{
            return self.defaults.string(forKey: "givenName")
        }
        set(givenName){
            defaults.set(givenName, forKey: "givenName")
        }
    }
    var familyName: String?{
        get{
            return self.defaults.string(forKey: "familyName")
        }
        set(familyName){
            defaults.set(familyName, forKey: "familyName")
        }
    }
    var state: String?{
        get{
            return self.defaults.string(forKey: "state")
        }
        set(state){
            defaults.set(state, forKey: "state")
        }
    }
    
}

