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
            VStack {
                if model.isSignedIn == false {
                    Text("🌹")
                        .font(.system(size: 50)).padding()
                    Text("🌱")
                        .font(.system(size: 50)).padding()
                    Text("🥀")
                        .font(.system(size: 50)).padding()
                    
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
                    }).frame(width: 200, height: 30).signInWithAppleButtonStyle(.black)
                     
                    
                }
                else{
                    ContentView()
                }
                
            }

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
