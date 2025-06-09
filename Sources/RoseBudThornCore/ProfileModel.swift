//
//  ProfileModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/24/21.
//

import Foundation

public struct ProfileModel{
    
    private let defaults = UserDefaults.standard
    
    public init(){

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
    
    // MARK: - Facebook Authentication Properties
    
    var facebookAccessToken: String?{
        get{
            return self.defaults.string(forKey: "facebookAccessToken")
        }
        set(facebookAccessToken){
            defaults.set(facebookAccessToken, forKey: "facebookAccessToken")
        }
    }
    
    var facebookUserId: String?{
        get{
            return self.defaults.string(forKey: "facebookUserId")
        }
        set(facebookUserId){
            defaults.set(facebookUserId, forKey: "facebookUserId")
        }
    }
    
    var profilePictureURL: String?{
        get{
            return self.defaults.string(forKey: "profilePictureURL")
        }
        set(profilePictureURL){
            defaults.set(profilePictureURL, forKey: "profilePictureURL")
        }
    }
    
    var authProvider: String?{
        get{
            return self.defaults.string(forKey: "authProvider")
        }
        set(authProvider){
            defaults.set(authProvider, forKey: "authProvider")
        }
    }
    
    // MARK: - Google Authentication Properties
    
    var googleAccessToken: String?{
        get{
            return self.defaults.string(forKey: "googleAccessToken")
        }
        set(googleAccessToken){
            defaults.set(googleAccessToken, forKey: "googleAccessToken")
        }
    }
    
    var googleIdToken: String?{
        get{
            return self.defaults.string(forKey: "googleIdToken")
        }
        set(googleIdToken){
            defaults.set(googleIdToken, forKey: "googleIdToken")
        }
    }
    
    var googleUserId: String?{
        get{
            return self.defaults.string(forKey: "googleUserId")
        }
        set(googleUserId){
            defaults.set(googleUserId, forKey: "googleUserId")
        }
    }
    
}

