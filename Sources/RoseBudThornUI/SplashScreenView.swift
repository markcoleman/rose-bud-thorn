//
//  SplashScreenView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/21/21.
//

import SwiftUI
import AuthenticationServices
import RoseBudThornCore

// MARK: - Social Auth Button Styles

struct SocialAuthButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let isLoading: Bool
    
    init(
        backgroundColor: Color,
        foregroundColor: Color = .white,
        isLoading: Bool = false
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Spacing.small) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                    .scaleEffect(0.8)
                    .accessibilityHidden(true)
            }
            
            configuration.label
                .font(.rbtBody.weight(.medium)) // iOS 15 compatible font weight
        }
        .frame(width: 200, height: DesignTokens.buttonHeight)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(DesignTokens.cornerRadiusMedium)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .opacity(configuration.isPressed ? 0.9 : 1.0)
        .opacity(isLoading ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(isLoading)
    }
}

struct FacebookButtonStyle: View {
    let action: () -> Void
    let isLoading: Bool
    let errorMessage: String?
    
    init(
        action: @escaping () -> Void,
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.action = action
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            Button(action: action) {
                HStack(spacing: Spacing.small) {
                    // Facebook "f" icon
                    Text("f")
                        .font(.rbtHeadline.weight(.bold)) // iOS 15 compatible font weight
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .accessibilityHidden(true)
                    
                    Text("Continue with Facebook")
                        .font(.rbtBody.weight(.medium)) // iOS 15 compatible font weight
                }
            }
            .buttonStyle(SocialAuthButtonStyle(
                backgroundColor: Color(red: 0.094, green: 0.467, blue: 0.949), // #1877F2
                foregroundColor: .white,
                isLoading: isLoading
            ))
            .accessibilityLabel("Continue with Facebook")
            .accessibilityHint("Sign in or create an account using your Facebook credentials")
            .disabled(isLoading) // Use disabled instead of accessibility trait
            
            // Privacy notice as per requirements
            Text("We'll never post to Facebook without your permission.")
                .font(.rbtCaption)
                .foregroundColor(DesignTokens.secondaryText)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Privacy notice: We'll never post to Facebook without your permission")
            
            // Error message display
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.rbtCaption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.medium)
                    .accessibilityLabel("Error: \(errorMessage)")
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }
}

struct GoogleButtonStyle: View {
    let action: () -> Void
    let isLoading: Bool
    let errorMessage: String?
    
    init(
        action: @escaping () -> Void,
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) {
        self.action = action
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            Button(action: action) {
                HStack(spacing: Spacing.small) {
                    // Google "G" icon with accurate colors and styling
                    ZStack {
                        // White background circle for contrast
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color(red: 0.859, green: 0.859, blue: 0.859), lineWidth: 1)
                            )
                        
                        // Google "G" with multicolor styling
                        Text("G")
                            .font(.rbtHeadline.weight(.medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.259, green: 0.522, blue: 0.957), // Google Blue
                                        Color(red: 0.208, green: 0.686, blue: 0.376), // Google Green
                                        Color(red: 0.984, green: 0.737, blue: 0.020), // Google Yellow
                                        Color(red: 0.918, green: 0.263, blue: 0.208)  // Google Red
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .accessibilityHidden(true)
                    
                    Text("Sign in with Google")
                        .font(.rbtBody.weight(.medium))
                }
            }
            .buttonStyle(SocialAuthButtonStyle(
                backgroundColor: .white,
                foregroundColor: Color(red: 0.259, green: 0.259, blue: 0.259), // Google Gray
                isLoading: isLoading
            ))
            .accessibilityLabel("Sign in with Google")
            .accessibilityHint("Sign in or create an account using your Google credentials")
            .disabled(isLoading)
            
            // Error message display
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.rbtCaption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.medium)
                    .accessibilityLabel("Error: \(errorMessage)")
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
  /// Marks this view as decorative and hides it from accessibility.
  func decorativeAccessibility() -> some View {
    self.accessibilityHidden(true)
  }
}

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
                     
                    // Facebook Login Button
                    FacebookButtonStyle(
                        action: {
                            Task {
                                await model.loginWithFacebook()
                            }
                        },
                        isLoading: model.isLoading,
                        errorMessage: model.errorMessage
                    )
                    .padding(.top, Spacing.medium)
                    
                    // Google Login Button
                    GoogleButtonStyle(
                        action: {
                            Task {
                                await model.loginWithGoogle()
                            }
                        },
                        isLoading: model.isLoading,
                        errorMessage: model.errorMessage
                    )
                    .padding(.top, Spacing.medium)
                     
                    
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
