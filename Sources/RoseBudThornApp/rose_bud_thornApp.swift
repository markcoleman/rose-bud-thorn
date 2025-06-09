//
//  rose_bud_thornApp.swift
//  Shared
//
//  Created by Mark Coleman on 12/5/21.
//

import SwiftUI
import RoseBudThornCore
import RoseBudThornUI

@main
struct rose_bud_thornApp: App {
    
    @StateObject var appState = AppState.shared
    init(){
        //ItemService.loadTestData()
    }
    var body: some Scene {
        WindowGroup {
            SplashScreenView(model: AuthViewModel(model: ProfileModel())).id(appState.gameID)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        if url.scheme == "rosebud" && url.host == "today" {
            // TODO: Navigate to today's summary
            // For now, we'll just trigger a state change to ensure the app is visible
            appState.navigateToToday = true
        }
    }
}

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var gameID = UUID()
    @Published var navigateToToday = false
}
