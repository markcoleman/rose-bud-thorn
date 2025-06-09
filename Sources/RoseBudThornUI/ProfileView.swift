//
//  ProfileView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/5/21.
//

import SwiftUI
import RoseBudThornCore

struct ProfileView: View {
    
    @ObservedObject
    var viewModel: ProfileViewModel
    var body: some View {
        VStack(spacing: Spacing.large){
            Label{
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(viewModel.model.familyName ?? "Family Name")
                        .font(.rbtBody)
                        .foregroundColor(DesignTokens.primaryText)
                    Text(viewModel.model.email ?? "Email")
                        .font(.rbtSubheadline)
                        .foregroundColor(DesignTokens.secondaryText)
                }
            } icon: {
                Circle()
                    .fill(DesignTokens.accentColor)
                    .frame(width: DesignTokens.iconSize, height: DesignTokens.iconSize, alignment: .center)
                    .overlay(
                        Text(viewModel.model.givenName ?? "User")
                            .font(.rbtHeadline)
                            .foregroundColor(DesignTokens.primaryBackground)
                    )
                    .accessibilityLabel("Profile picture for \(viewModel.model.givenName ?? "user")")
            }
            
            LiveActivityControl()
            
            Button("Sign Out", action: {
                viewModel.signOut()
                AppState.shared.gameID = UUID()
            })
            .accessibleTouchTarget(label: "Sign Out", hint: "Sign out of your account")
            .frame(height: DesignTokens.buttonHeight)
            .padding(.horizontal, Spacing.large)
            .background(DesignTokens.accentColor)
            .foregroundColor(DesignTokens.primaryBackground)
            .cornerRadius(DesignTokens.cornerRadiusMedium)
        }
        .padding(Spacing.medium)
        .background(DesignTokens.primaryBackground)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: ProfileViewModel(model: ProfileModel()))
    }
}
