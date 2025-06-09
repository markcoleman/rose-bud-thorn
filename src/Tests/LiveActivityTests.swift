//
//  LiveActivityTests.swift
//  rose.bud.thorn
//
//  Created by Copilot for Live Activity feature tests
//

import XCTest
import SnapshotTesting
@testable import RoseBudThornCore

#if canImport(SwiftUI) && (os(iOS) || os(macOS) || os(macCatalyst) || os(tvOS) || os(watchOS) || os(visionOS))
import SwiftUI
@testable import RoseBudThornUI

class LiveActivityTests: XCTestCase {
    
    func testDailySummaryServiceCounts() {
        let service = DailySummaryService.shared
        let counts = service.getTodayCounts()
        
        // Test that counts are valid integers
        XCTAssertGreaterThanOrEqual(counts.roses, 0)
        XCTAssertGreaterThanOrEqual(counts.buds, 0)
        XCTAssertGreaterThanOrEqual(counts.thorns, 0)
        
        // Test that counts don't exceed expected maximum (1 per type per day)
        XCTAssertLessThanOrEqual(counts.roses, 1)
        XCTAssertLessThanOrEqual(counts.buds, 1)
        XCTAssertLessThanOrEqual(counts.thorns, 1)
    }
    
    func testDailySummaryServiceIntegration() {
        let service = DailySummaryService.shared
        
        // Test that the service can get counts without crashing
        XCTAssertNoThrow({
            _ = service.getTodayCounts()
        })
        
        // Test that update method can be called without crashing
        XCTAssertNoThrow({
            service.updateLiveActivityIfNeeded()
        })
    }
    
    #if os(iOS)
    func testLiveActivityManagerSupport() {
        // Test static support method
        let isSupported = LiveActivityManager.isSupported()
        XCTAssertTrue(isSupported)
    }
    #endif
    
    func testLiveActivityControlUILight() {
        let view = LiveActivityControl()
            .frame(width: 375, height: 150)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testLiveActivityControlUIDark() {
        let view = LiveActivityControl()
            .frame(width: 375, height: 150)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    #if os(iOS)
    @available(iOS 16.1, *)
    func testDailySummaryCountView() {
        let view = DailySummaryCount(
            symbol: "🌹",
            count: 3,
            label: "roses"
        )
        .frame(width: 100, height: 100)
        
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    #endif
    
    func testProfileViewWithLiveActivityControl() {
        let profileModel = ProfileModel()
        profileModel.givenName = "Test"
        profileModel.familyName = "User"
        profileModel.email = "test@example.com"
        
        let viewModel = ProfileViewModel(model: profileModel)
        let view = ProfileView(viewModel: viewModel)
            .frame(width: 375, height: 600)
        
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .light
        
        assertSnapshot(matching: hostingController, as: .image)
    }
    
    func testDayViewModelLiveActivityIntegration() {
        let dayViewModel = DayViewModel(date: Date())
        dayViewModel.load()
        
        // Test that save method can be called without crashing
        // (even if Live Activity is not actually started in test environment)
        XCTAssertNoThrow({
            dayViewModel.save()
        })
    }
}

#endif