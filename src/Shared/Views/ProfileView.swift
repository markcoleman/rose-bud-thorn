//
//  ProfileView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/5/21.
//

import SwiftUI

struct ProfileView: View {
    
    @ObservedObject
    var viewModel: ProfileViewModel
    var body: some View {
        VStack{
            Label{
                Text(viewModel.model.familyName ?? "familyName")
                        .font(.body)
                        .foregroundColor(.primary)
                Text(viewModel.model.email ?? "email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
            }   icon: {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 44, height: 44, alignment: .center)
                    .overlay(Text(viewModel.model.givenName ?? "givenName"))
            
                Button("Sign Out", action: {
                    viewModel.signOut()
                    AppState.shared.gameID = UUID()
                }).padding()
            }
            
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: ProfileViewModel(model: ProfileModel()))
    }
}
