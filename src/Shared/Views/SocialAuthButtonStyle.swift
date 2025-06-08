//
//  SocialAuthButtonStyle.swift
//  rose.bud.thorn
//
//  Created by Copilot for reusable social authentication button styling
//

import SwiftUI

// MARK: - Social Auth Button Style

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
                .font(.rbtBody)
                .fontWeight(.medium)
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

// MARK: - Facebook Button Specific Style

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
                        .font(.rbtHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .accessibilityHidden(true)
                    
                    Text("Continue with Facebook")
                        .font(.rbtBody)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(SocialAuthButtonStyle(
                backgroundColor: Color(red: 0.094, green: 0.467, blue: 0.949), // #1877F2
                foregroundColor: .white,
                isLoading: isLoading
            ))
            .accessibilityLabel("Continue with Facebook")
            .accessibilityHint("Sign in or create an account using your Facebook credentials")
            .accessibilityAddTraits(isLoading ? [.notEnabled] : [])
            
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

// MARK: - Preview Extensions

extension Color {
    static let facebookBlue = Color(red: 0.094, green: 0.467, blue: 0.949) // #1877F2
}

// MARK: - Previews

struct SocialAuthButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.large) {
            // Normal state
            FacebookButtonStyle(action: {}) {
            }
            
            // Loading state
            FacebookButtonStyle(action: {}, isLoading: true)
            
            // Error state
            FacebookButtonStyle(
                action: {},
                errorMessage: "Facebook login was canceled or failed. Please try again."
            )
        }
        .padding()
        .background(DesignTokens.primaryBackground)
        .previewDisplayName("Facebook Button States")
    }
}