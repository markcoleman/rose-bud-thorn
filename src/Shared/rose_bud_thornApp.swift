//
//  rose_bud_thornApp.swift
//  Shared
//
//  Created by Mark Coleman on 12/5/21.
//

import SwiftUI

@main
struct rose_bud_thornApp: App {
    
    @StateObject var appState = AppState.shared
    init(){
        //ItemService.loadTestData()
    }
    var body: some Scene {
        WindowGroup {
            SplashScreenView(model: AuthViewModel(model: ProfileModel())).id(appState.gameID)
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var gameID = UUID()
}
