//
//  Item.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/29/21.
//

import Foundation

struct Item{
    var id: UUID?
    var mediaUrl: String
    var type: ItemType
    var note: String = ""
}

enum ItemType {
    case Rose
    case Bud
    case Thorn
}
