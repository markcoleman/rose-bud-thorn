//
//  SnapshotTests.swift
//  rose.bud.thorn
//
//  Created by Copilot for UI snapshot testing
//

import XCTest
import SnapshotTesting
@testable import RoseBudThornCore

#if canImport(SwiftUI) && (os(iOS) || os(macOS) || os(macCatalyst) || os(tvOS) || os(watchOS) || os(visionOS))
import SwiftUI
@testable import RoseBudThornUI

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
    
    func testAddNewRBTViewLightMode() {
        let dayViewModel = DayViewModel(date: Date())
        let view = AddNewRBTView(viewModel: dayViewModel)
            .frame(width: 375, height: 800)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testAddNewRBTViewDarkMode() {
        let dayViewModel = DayViewModel(date: Date())
        let view = AddNewRBTView(viewModel: dayViewModel)
            .frame(width: 375, height: 800)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(matching: hostingController, as: .image)
    }
}

#endif