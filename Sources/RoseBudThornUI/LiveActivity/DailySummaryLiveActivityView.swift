//
//  DailySummaryLiveActivityView.swift
//  rose.bud.thorn
//
//  Created by Copilot for Live Activity feature
//

import Foundation
import SwiftUI
import RoseBudThornCore

#if os(iOS)
import ActivityKit
import WidgetKit

@available(iOS 16.1, *)
struct DailySummaryLiveActivityView: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DailySummaryAttributes.self) { context in
            // Lock Screen/Banner view
            DailySummaryLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island views
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    DailySummaryCount(
                        symbol: "🌹",
                        count: context.state.roses,
                        label: NSLocalizedString("roses", comment: "Roses count label")
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DailySummaryCount(
                        symbol: "🌱",
                        count: context.state.buds,
                        label: NSLocalizedString("buds", comment: "Buds count label")
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    DailySummaryCount(
                        symbol: "🌵",
                        count: context.state.thorns,
                        label: NSLocalizedString("thorns", comment: "Thorns count label")
                    )
                }
            } compactLeading: {
                Text("🌹\(context.state.roses)")
                    .font(.system(size: 14, weight: .semibold))
            } compactTrailing: {
                Text("🌱\(context.state.buds)")
                    .font(.system(size: 14, weight: .semibold))
            } minimal: {
                Text("RBT")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
    }
}

@available(iOS 16.1, *)
struct DailySummaryLockScreenView: View {
    let context: ActivityViewContext<DailySummaryAttributes>
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            Text("Today's Reflections")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(DesignTokens.primaryText)
                .accessibilityLabel("Today's Reflections Summary")
            
            HStack(spacing: Spacing.large) {
                DailySummaryCount(
                    symbol: "🌹",
                    count: context.state.roses,
                    label: NSLocalizedString("roses", comment: "Roses count label")
                )
                
                DailySummaryCount(
                    symbol: "🌱",
                    count: context.state.buds,
                    label: NSLocalizedString("buds", comment: "Buds count label")
                )
                
                DailySummaryCount(
                    symbol: "🌵",
                    count: context.state.thorns,
                    label: NSLocalizedString("thorns", comment: "Thorns count label")
                )
            }
        }
        .padding(Spacing.medium)
        .background(DesignTokens.secondaryBackground.opacity(0.1))
        .cornerRadius(DesignTokens.cornerRadiusMedium)
        .widgetURL(URL(string: "rosebud://today"))
    }
}

@available(iOS 16.1, *)
struct DailySummaryCount: View {
    let symbol: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: Spacing.xxSmall) {
            Text(symbol)
                .font(.system(size: 24))
                .accessibilityHidden(true)
            
            Text("\(count)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(DesignTokens.primaryText)
            
            Text(label)
                .font(.caption)
                .foregroundColor(DesignTokens.secondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label)")
    }
}
#endif