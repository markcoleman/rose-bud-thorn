//
//  JournalService.swift
//  rose.bud.thorn
//
//  Created by Copilot for JournalKit integration
//

import Foundation
import os.log

#if canImport(JournalKit)
import JournalKit
#endif

/// Service for managing JournalKit integration and reflection prompts
@available(iOS 18.0, *)
@MainActor
class JournalService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var authorizationStatus: JournalAuthorizationStatus = .notDetermined
    @Published var prompts: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.eweandme.rose-bud-thorn", category: "JournalService")
    private let fallbackPrompt = "What's one small win you had today?"
    
    // MARK: - Initialization
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request authorization for JournalKit access
    func requestAuthorization() async {
        #if canImport(JournalKit)
        do {
            let status = try await JournalKit.requestAuthorization()
            await MainActor.run {
                self.authorizationStatus = status
                self.logger.info("JournalKit authorization status: \(String(describing: status))")
            }
        } catch {
            await MainActor.run {
                self.authorizationStatus = .denied
                self.logger.error("Failed to request JournalKit authorization: \(error.localizedDescription)")
            }
        }
        #else
        await MainActor.run {
            self.authorizationStatus = .denied
            self.logger.info("JournalKit not available on this platform")
        }
        #endif
    }
    
    /// Check current authorization status
    private func checkAuthorizationStatus() {
        #if canImport(JournalKit)
        authorizationStatus = JournalKit.authorizationStatus()
        #else
        authorizationStatus = .denied
        #endif
    }
    
    // MARK: - Prompt Fetching
    
    /// Fetch reflection prompts from JournalKit
    func fetchPrompts() async {
        guard authorizationStatus == .authorized else {
            await showFallbackPrompt()
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        #if canImport(JournalKit)
        do {
            let suggestions = try await JournalKit.fetchPrompts(limit: 3)
            let promptTexts = suggestions.compactMap { suggestion in
                // Extract meaningful text from JournalKit suggestions
                return extractPromptText(from: suggestion)
            }
            
            await MainActor.run {
                if promptTexts.isEmpty {
                    self.prompts = [self.fallbackPrompt]
                } else {
                    self.prompts = Array(promptTexts.prefix(3)) // Ensure we have at most 3 prompts
                }
                self.isLoading = false
                self.logger.info("Successfully fetched \(promptTexts.count) prompts from JournalKit")
            }
        } catch {
            await MainActor.run {
                self.prompts = [self.fallbackPrompt]
                self.errorMessage = "Failed to fetch prompts"
                self.isLoading = false
                self.logger.error("Failed to fetch JournalKit prompts: \(error.localizedDescription)")
            }
        }
        #else
        await showFallbackPrompt()
        #endif
    }
    
    /// Show fallback prompt when JournalKit is unavailable
    private func showFallbackPrompt() async {
        await MainActor.run {
            self.prompts = [self.fallbackPrompt]
            self.isLoading = false
            self.logger.info("Showing fallback prompt")
        }
    }
    
    // MARK: - Helper Methods
    
    #if canImport(JournalKit)
    /// Extract meaningful prompt text from JournalKit suggestion
    private func extractPromptText(from suggestion: JournalPrompt) -> String? {
        // JournalKit suggestions may have different formats
        // This implementation assumes the suggestion has a text property
        // In actual implementation, this would depend on the JournalKit API structure
        if let content = suggestion.content as? String {
            return content
        }
        
        // Fallback to a generic prompt based on suggestion type or content
        return "What made this moment meaningful to you?"
    }
    #endif
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Mock Implementation for Testing

/// Mock JournalService for testing and development
@MainActor
class MockJournalService: ObservableObject {
    
    @Published var authorizationStatus: JournalAuthorizationStatus = .authorized
    @Published var prompts: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let mockPrompts = [
        "What made you smile today?",
        "Describe a moment when you felt grateful.",
        "What's one thing you learned about yourself recently?",
        "How did you show kindness to someone today?",
        "What challenged you today and how did you handle it?"
    ]
    
    func requestAuthorization() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        authorizationStatus = .authorized
    }
    
    func fetchPrompts() async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return 3 random prompts
        let shuffled = mockPrompts.shuffled()
        prompts = Array(shuffled.prefix(3))
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - JournalAuthorizationStatus

/// Authorization status for JournalKit access
enum JournalAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
}

// MARK: - Mock JournalPrompt for Development

#if !canImport(JournalKit)
/// Mock JournalPrompt structure for development when JournalKit is not available
struct JournalPrompt {
    let content: Any
}
#endif