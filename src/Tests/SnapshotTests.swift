//
//  SnapshotTests.swift
//  rose.bud.thorn
//
//  Created by Copilot for UI snapshot testing
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import RoseBudThorn

class SnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Set to record snapshots initially, then change to false
        // isRecording = true
    }
    
    func testSplashScreenViewLightMode() {
        let model = AuthViewModel(model: ProfileModel())
        let view = SplashScreenView(model: model)
            .frame(width: 375, height: 667) // iPhone SE size
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testSplashScreenViewDarkMode() {
        let model = AuthViewModel(model: ProfileModel())
        let view = SplashScreenView(model: model)
            .frame(width: 375, height: 667) // iPhone SE size
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testSplashScreenViewLargeText() {
        let model = AuthViewModel(model: ProfileModel())
        let view = SplashScreenView(model: model)
            .frame(width: 375, height: 667) // iPhone SE size
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testItemViewWithData() {
        let item = Item(id: UUID(), mediaUrl: "https://example.com/image.jpg", type: .Rose, note: "This is a test note for the rose item")
        let view = ItemView(model: item)
            .frame(width: 375, height: 300)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testItemViewDarkMode() {
        let item = Item(id: UUID(), mediaUrl: "", type: .Bud, note: "A bud item in dark mode")
        let view = ItemView(model: item)
            .frame(width: 375, height: 300)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    // MARK: - Prompts View Snapshot Tests
    
    func testPromptsViewLightMode() {
        let promptsViewModel = createMockPromptsViewModel(withPrompts: true)
        let view = PromptsView(viewModel: promptsViewModel) { _ in }
            .frame(width: 375, height: 200)
            .padding()
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testPromptsViewDarkMode() {
        let promptsViewModel = createMockPromptsViewModel(withPrompts: true)
        let view = PromptsView(viewModel: promptsViewModel) { _ in }
            .frame(width: 375, height: 200)
            .padding()
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testPromptsViewLoadingState() {
        let promptsViewModel = createMockPromptsViewModel(loading: true)
        let view = PromptsView(viewModel: promptsViewModel) { _ in }
            .frame(width: 375, height: 100)
            .padding()
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testPromptsViewDynamicType() {
        let promptsViewModel = createMockPromptsViewModel(withPrompts: true)
        let view = PromptsView(viewModel: promptsViewModel) { _ in }
            .frame(width: 375, height: 300)
            .padding()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testAddNewRBTViewWithPrompts() {
        let dayViewModel = DayViewModel(date: Date())
        let view = AddNewRBTView(viewModel: dayViewModel)
            .frame(width: 375, height: 800)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testAddNewRBTViewWithPromptsDarkMode() {
        let dayViewModel = DayViewModel(date: Date())
        let view = AddNewRBTView(viewModel: dayViewModel)
            .frame(width: 375, height: 800)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    // MARK: - Helper Methods
    
    private func createMockPromptsViewModel(withPrompts: Bool = false, loading: Bool = false) -> PromptsViewModel {
        let viewModel = PromptsViewModel()
        viewModel.authorizationStatus = .authorized
        
        if loading {
            viewModel.isLoading = true
        } else if withPrompts {
            viewModel.prompts = [
                "What made you smile today?",
                "Describe a moment when you felt grateful.",
                "What's one thing you learned about yourself recently?"
            ]
        }
        
        return viewModel
    }
}