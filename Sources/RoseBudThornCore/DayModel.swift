//
//  DayModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/6/21.
//

import Foundation

public struct DayModel {
    var date: Date
    var id: UUID?
    var bud: Item
    var rose: Item
    var thorn: Item
    
    public init(date: Date, rose: Item?, bud: Item?, thorn: Item?) {
        self.date = date
        self.id = UUID()
        self.rose = rose ?? Item(id: nil, mediaUrl: "", type: .Rose, note: "")
        self.thorn = thorn ?? Item(id: nil, mediaUrl: "", type: .Thorn, note: "")
        self.bud = bud ?? Item(id: nil, mediaUrl: "", type: .Bud, note: "")
    }
    
    var hasEvent: Bool{
        return bud.id != nil || rose.id != nil || thorn.id != nil
    }
}
