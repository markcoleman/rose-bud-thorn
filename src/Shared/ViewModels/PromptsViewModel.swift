//
//  PromptsViewModel.swift
//  rose.bud.thorn
//
//  Created by Copilot for JournalKit prompts integration
//

import Foundation
import SwiftUI

/// View model for managing reflection prompts in the AddNewRBTView
@MainActor
class PromptsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var prompts: [String] = []
    @Published var isLoading: Bool = false
    @Published var authorizationStatus: JournalAuthorizationStatus = .notDetermined
    @Published var showAuthorizationAlert: Bool = false
    @Published var hasRequestedAuthorization: Bool = false
    
    // MARK: - Private Properties
    
    private let journalService: JournalService?
    private let mockService: MockJournalService?
    
    // MARK: - Initialization
    
    init() {
        // Use real JournalService on iOS 18+, otherwise use mock
        if #available(iOS 18.0, *) {
            self.journalService = JournalService()
            self.mockService = nil
        } else {
            self.journalService = nil
            self.mockService = MockJournalService()
        }
    }
    
    // MARK: - Public Methods
    
    /// Request authorization and fetch prompts if needed
    func loadPromptsIfNeeded() async {
        await checkAuthorizationAndFetchPrompts()
    }
    
    /// Refresh prompts (for pull-to-refresh)
    func refreshPrompts() async {
        await fetchPrompts()
    }
    
    /// Handle prompt selection - returns the selected prompt text
    func selectPrompt(_ prompt: String) -> String {
        return prompt
    }
    
    /// Request authorization when user hasn't been asked yet
    func requestAuthorizationIfNeeded() async {
        guard !hasRequestedAuthorization else { return }
        
        hasRequestedAuthorization = true
        
        if #available(iOS 18.0, *), let service = journalService {
            await service.requestAuthorization()
            // Manually sync the authorization status
            authorizationStatus = service.authorizationStatus
        } else if let service = mockService {
            await service.requestAuthorization()
            // Manually sync the authorization status
            authorizationStatus = service.authorizationStatus
        }
        
        await fetchPrompts()
    }
    
    /// Show authorization rationale alert
    func showAuthorizationRationale() {
        showAuthorizationAlert = true
    }
    
    /// Dismiss authorization alert and request permission
    func handleAuthorizationAlert() async {
        showAuthorizationAlert = false
        await requestAuthorizationIfNeeded()
    }
    
    // MARK: - Private Methods
    
    private func checkAuthorizationAndFetchPrompts() async {
        if authorizationStatus == .notDetermined {
            showAuthorizationRationale()
        } else if authorizationStatus == .authorized {
            await fetchPrompts()
        }
        // If denied, don't show prompts section
    }
    
    private func fetchPrompts() async {
        isLoading = true
        
        if #available(iOS 18.0, *), let service = journalService {
            await service.fetchPrompts()
            // Manually sync the state since we simplified the observer pattern
            prompts = service.prompts
            authorizationStatus = service.authorizationStatus
        } else if let service = mockService {
            await service.fetchPrompts()
            // Manually sync the state since we simplified the observer pattern
            prompts = service.prompts
            authorizationStatus = service.authorizationStatus
        }
        
        isLoading = false
    }
    
    // MARK: - Service Observers Setup
    
    @available(iOS 18.0, *)
    private func setupServiceObservers(service: JournalService) {
        // Monitor service state changes via Combine
        // Note: This is a simplified implementation for iOS 18 beta compatibility
        // In a production app, you might want to use proper Combine publishers
    }
    
    private func setupMockServiceObservers(service: MockJournalService) {
        // Monitor mock service state changes via Combine  
        // Note: This is a simplified implementation for development
        // In a production app, you might want to use proper Combine publishers
    }
}

// MARK: - View Extensions for Prompts

extension View {
    /// Modifier to handle prompts authorization flow
    func promptsAuthorizationAlert(
        isPresented: Binding<Bool>,
        onAuthorize: @escaping () async -> Void
    ) -> some View {
        self.alert(
            "Personalized Reflection Prompts",
            isPresented: isPresented
        ) {
            Button("Allow") {
                Task {
                    await onAuthorize()
                }
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Rose Bud Thorn can suggest personalized reflection prompts based on your activity to help inspire meaningful entries.")
        }
    }
}