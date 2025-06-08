//
//  JournalServiceTests.swift
//  rose.bud.thorn
//
//  Created by Copilot for JournalKit integration tests
//

import XCTest
@testable import RoseBudThorn

@MainActor
class JournalServiceTests: XCTestCase {
    
    var mockService: MockJournalService!
    
    override func setUpWithError() throws {
        super.setUp()
        mockService = MockJournalService()
    }
    
    override func tearDownWithError() throws {
        mockService = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testInitialAuthorizationStatus() throws {
        // Given: A new mock service
        // When: We check the initial status
        // Then: It should be authorized for testing
        XCTAssertEqual(mockService.authorizationStatus, .authorized)
    }
    
    func testRequestAuthorization() async throws {
        // Given: A mock service with not determined status
        mockService.authorizationStatus = .notDetermined
        
        // When: We request authorization
        await mockService.requestAuthorization()
        
        // Then: Status should be authorized
        XCTAssertEqual(mockService.authorizationStatus, .authorized)
    }
    
    // MARK: - Prompt Fetching Tests
    
    func testFetchPromptsSuccessfully() async throws {
        // Given: A mock service with authorized status
        XCTAssertEqual(mockService.authorizationStatus, .authorized)
        XCTAssertTrue(mockService.prompts.isEmpty)
        
        // When: We fetch prompts
        await mockService.fetchPrompts()
        
        // Then: We should have 3 prompts
        XCTAssertEqual(mockService.prompts.count, 3)
        XCTAssertFalse(mockService.isLoading)
        XCTAssertNil(mockService.errorMessage)
    }
    
    func testFetchPromptsReturnsValidContent() async throws {
        // Given: A mock service
        // When: We fetch prompts
        await mockService.fetchPrompts()
        
        // Then: All prompts should be valid strings
        XCTAssertEqual(mockService.prompts.count, 3)
        for prompt in mockService.prompts {
            XCTAssertFalse(prompt.isEmpty)
            XCTAssertTrue(prompt.count > 10) // Reasonable minimum length
            XCTAssertTrue(prompt.hasSuffix("?") || prompt.contains(".")) // Should be a question or statement
        }
    }
    
    func testFetchPromptsLoadingState() async throws {
        // Given: A mock service
        XCTAssertFalse(mockService.isLoading)
        
        // When: We start fetching prompts
        let fetchTask = Task {
            await mockService.fetchPrompts()
        }
        
        // Brief delay to check loading state
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Loading should be true initially
        XCTAssertTrue(mockService.isLoading)
        
        // Wait for completion
        await fetchTask.value
        
        // Then: Loading should be false after completion
        XCTAssertFalse(mockService.isLoading)
    }
    
    func testClearError() throws {
        // Given: A service with an error
        mockService.errorMessage = "Test error"
        
        // When: We clear the error
        mockService.clearError()
        
        // Then: Error should be nil
        XCTAssertNil(mockService.errorMessage)
    }
}

// MARK: - PromptsViewModel Tests

@MainActor
class PromptsViewModelTests: XCTestCase {
    
    var viewModel: PromptsViewModel!
    
    override func setUpWithError() throws {
        super.setUp()
        viewModel = PromptsViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() throws {
        // Given: A new view model
        // Then: Initial state should be correct
        XCTAssertTrue(viewModel.prompts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showAuthorizationAlert)
        XCTAssertFalse(viewModel.hasRequestedAuthorization)
    }
    
    func testSelectPrompt() throws {
        // Given: A prompt string
        let testPrompt = "What made you smile today?"
        
        // When: We select the prompt
        let result = viewModel.selectPrompt(testPrompt)
        
        // Then: It should return the same prompt
        XCTAssertEqual(result, testPrompt)
    }
    
    func testShowAuthorizationRationale() throws {
        // Given: A view model with alert not shown
        XCTAssertFalse(viewModel.showAuthorizationAlert)
        
        // When: We show the authorization rationale
        viewModel.showAuthorizationRationale()
        
        // Then: Alert should be shown
        XCTAssertTrue(viewModel.showAuthorizationAlert)
    }
    
    func testHandleAuthorizationAlert() async throws {
        // Given: A view model with alert shown
        viewModel.showAuthorizationAlert = true
        
        // When: We handle the authorization alert
        await viewModel.handleAuthorizationAlert()
        
        // Then: Alert should be dismissed and authorization requested
        XCTAssertFalse(viewModel.showAuthorizationAlert)
        XCTAssertTrue(viewModel.hasRequestedAuthorization)
    }
}