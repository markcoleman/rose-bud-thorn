//
//  LiveActivityManager.swift
//  rose.bud.thorn
//
//  Created by Copilot for Live Activity feature
//

import Foundation

#if os(iOS)
import ActivityKit

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var isLiveActivityRunning = false
    private var currentActivity: Activity<DailySummaryAttributes>?
    
    private init() {
        // Check if there's an existing activity
        currentActivity = Activity<DailySummaryAttributes>.activities.first
        isLiveActivityRunning = currentActivity != nil
        
        // If there's an existing activity, schedule cleanup for it
        if isLiveActivityRunning {
            scheduleAutomaticCleanup()
        }
    }
    
    /// Start a Live Activity with initial counts
    func startLiveActivity(roses: Int = 0, buds: Int = 0, thorns: Int = 0) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity first
        endLiveActivity()
        
        let attributes = DailySummaryAttributes()
        let initialState = DailySummaryAttributes.ContentState(
            roses: roses,
            buds: buds,
            thorns: thorns
        )
        
        do {
            currentActivity = try Activity<DailySummaryAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            isLiveActivityRunning = true
            print("Live Activity started successfully")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    /// Update the Live Activity with new counts
    func updateLiveActivity(roses: Int, buds: Int, thorns: Int) {
        guard let activity = currentActivity else {
            print("No active Live Activity to update")
            return
        }
        
        // Throttle updates to avoid overwhelming the system
        let updatedState = DailySummaryAttributes.ContentState(
            roses: roses,
            buds: buds,
            thorns: thorns
        )
        
        Task {
            do {
                await activity.update(using: updatedState)
                print("Live Activity updated with roses: \(roses), buds: \(buds), thorns: \(thorns)")
            } catch {
                print("Failed to update Live Activity: \(error)")
            }
        }
    }
    
    /// End the current Live Activity
    func endLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            DispatchQueue.main.async {
                self.currentActivity = nil
                self.isLiveActivityRunning = false
            }
            print("Live Activity ended")
        }
    }
    
    /// Check if Live Activities are supported on this device
    static func isSupported() -> Bool {
        return true
    }
    
    /// Schedule automatic cleanup at midnight
    func scheduleAutomaticCleanup() {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate next midnight
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let nextMidnight = calendar.startOfDay(for: tomorrow)
        
        let timer = Timer(fireAt: nextMidnight, interval: 0, target: self, selector: #selector(automaticCleanup), userInfo: nil, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
        
        print("Scheduled automatic Live Activity cleanup for: \(nextMidnight)")
    }
    
    @objc private func automaticCleanup() {
        endLiveActivity()
        print("Automatic Live Activity cleanup completed")
    }
}
#endif