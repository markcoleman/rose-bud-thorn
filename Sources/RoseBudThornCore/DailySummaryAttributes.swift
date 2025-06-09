//
//  DailySummaryAttributes.swift
//  rose.bud.thorn
//
//  Created by Copilot for Live Activity feature
//

import Foundation

#if os(iOS)
import ActivityKit

@available(iOS 16.1, *)
struct DailySummaryAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var roses: Int
        var buds: Int
        var thorns: Int
    }
}
#endif