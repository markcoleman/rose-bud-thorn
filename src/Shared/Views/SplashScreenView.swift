//
//  SplashScreenView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/21/21.
//

import SwiftUI
import AuthenticationServices

struct SplashScreenView: View {
    @ObservedObject
    var model: AuthViewModel
    
  

    
        var body: some View {
            VStack(spacing: Spacing.large) {
                if model.isSignedIn == false {
                    VStack(spacing: Spacing.medium) {
                        Text("🌹")
                            .font(.rbtLargeTitle)
                            .decorativeAccessibility()
                        Text("🌱")
                            .font(.rbtLargeTitle)
                            .decorativeAccessibility()
                        Text("🥀")
                            .font(.rbtLargeTitle)
                            .decorativeAccessibility()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Rose Bud Thorn app logo")
                    
                    SignInWithAppleButton(.signIn,              //1
                      onRequest: { (request) in             //2
                        request.requestedScopes = [.fullName, .email]
                        //request.nonce = myNonceString()
                        //request.state = myStateString()
                        print("request: \(self.model.isSignedIn)")
                      },
                      onCompletion: { (result) in           //3
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                self.model.save(appleIDCredential: appleIDCredential)
                            }
                            print("success")
                            break
                        case .failure(_):
                            //Handle error
                            break
                        }
                    }).frame(width: 200, height: DesignTokens.buttonHeight)
                      .signInWithAppleButtonStyle(.black)
                      .accessibilityLabel("Sign in with Apple")
                      .accessibilityHint("Authenticate with your Apple ID to use the app")
                     
                    
                }
                else{
                    ContentView()
                }
                
            }
            .background(DesignTokens.primaryBackground)
            .onAppear {
               
            }
        }
        
}


/*struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(model: AuthViewModel(model: ProfileModel()))
    }
}
*/
