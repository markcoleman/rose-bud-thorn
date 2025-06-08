//
//  LiveActivityControl.swift
//  rose.bud.thorn
//
//  Created by Copilot for Live Activity feature
//

import SwiftUI

struct LiveActivityControl: View {
    #if os(iOS)
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    #endif
    
    var body: some View {
        #if os(iOS)
        VStack(spacing: Spacing.small) {
            HStack {
                Text("Live Activity")
                    .font(.rbtHeadline)
                    .foregroundColor(DesignTokens.primaryText)
                
                Spacer()
                
                if liveActivityManager.isLiveActivityRunning {
                    Button(action: {
                        liveActivityManager.endLiveActivity()
                    }) {
                        Text("Stop")
                            .font(.rbtCallout)
                            .foregroundColor(.red)
                    }
                    .accessibleTouchTarget(
                        label: "Stop Live Activity",
                        hint: "Removes the daily summary from your Lock Screen"
                    )
                } else {
                    Button(action: {
                        DailySummaryService.shared.startLiveActivityWithCurrentCounts()
                    }) {
                        Text("Start")
                            .font(.rbtCallout)
                            .foregroundColor(DesignTokens.accentColor)
                    }
                    .accessibleTouchTarget(
                        label: "Start Live Activity",
                        hint: "Shows your daily summary on the Lock Screen"
                    )
                }
            }
            
            Text("Show today's Rose, Bud, and Thorn count on your Lock Screen")
                .font(.rbtCaption)
                .foregroundColor(DesignTokens.secondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.medium)
        .background(DesignTokens.secondaryBackground.opacity(0.5))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
        #else
        EmptyView()
        #endif
    }
}

struct LiveActivityControl_Previews: PreviewProvider {
    static var previews: some View {
        LiveActivityControl()
            .padding()
    }
}