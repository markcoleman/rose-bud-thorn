//
//  DailySummaryService.swift
//  rose.bud.thorn
//
//  Created by Copilot for Live Activity feature
//

import Foundation

class DailySummaryService {
    static let shared = DailySummaryService()
    private let itemService = ItemService()
    
    private init() {}
    
    /// Get counts for today's rose, bud, and thorn entries
    func getTodayCounts() -> (roses: Int, buds: Int, thorns: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let todayKey = dateFormatter.string(from: Date())
        
        let todayModel = itemService.getItem(id: todayKey)
        
        let roses = (todayModel.rose.id != nil && !todayModel.rose.note.isEmpty) ? 1 : 0
        let buds = (todayModel.bud.id != nil && !todayModel.bud.note.isEmpty) ? 1 : 0
        let thorns = (todayModel.thorn.id != nil && !todayModel.thorn.note.isEmpty) ? 1 : 0
        
        return (roses: roses, buds: buds, thorns: thorns)
    }
    
    /// Update Live Activity with current counts
    func updateLiveActivityIfNeeded() {
        #if os(iOS)
        if #available(iOS 16.1, *) {
            let counts = getTodayCounts()
            LiveActivityManager.shared.updateLiveActivity(
                roses: counts.roses,
                buds: counts.buds,
                thorns: counts.thorns
            )
        }
        #endif
    }
    
    /// Start Live Activity with current counts
    func startLiveActivityWithCurrentCounts() {
        #if os(iOS)
        if #available(iOS 16.1, *) {
            let counts = getTodayCounts()
            LiveActivityManager.shared.startLiveActivity(
                roses: counts.roses,
                buds: counts.buds,
                thorns: counts.thorns
            )
            LiveActivityManager.shared.scheduleAutomaticCleanup()
        }
        #endif
    }
}