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
            
            // Observe changes from the real service
            if let service = journalService {
                setupServiceObservers(service: service)
            }
        } else {
            self.journalService = nil
            self.mockService = MockJournalService()
            
            // Observe changes from the mock service
            if let service = mockService {
                setupMockServiceObservers(service: service)
            }
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
        } else if let service = mockService {
            await service.requestAuthorization()
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
        if #available(iOS 18.0, *), let service = journalService {
            await service.fetchPrompts()
        } else if let service = mockService {
            await service.fetchPrompts()
        }
    }
    
    // MARK: - Service Observers Setup
    
    @available(iOS 18.0, *)
    private func setupServiceObservers(service: JournalService) {
        // Monitor service state changes
        Task {
            for await _ in service.objectWillChange.values {
                await MainActor.run {
                    self.prompts = service.prompts
                    self.isLoading = service.isLoading
                    self.authorizationStatus = service.authorizationStatus
                }
            }
        }
    }
    
    private func setupMockServiceObservers(service: MockJournalService) {
        // Monitor mock service state changes
        Task {
            for await _ in service.objectWillChange.values {
                await MainActor.run {
                    self.prompts = service.prompts
                    self.isLoading = service.isLoading
                    self.authorizationStatus = service.authorizationStatus
                }
            }
        }
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