//
//  ItemViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/29/21.
//

import Foundation
import RoseBudThornCore

class ItemViewModel: ObservableObject {
    
    @Published
    var model: Item
    
    private var itemService: ItemService = ItemService()
    
    init(model: Item){
        self.model = model
    }
    func save(){
        if(model.id == nil){
            model.id = UUID()
        }
        dump(model)
        itemService.saveItem(item: self.model)
    }
    
    var toTitle: String{
        var title = ""
        if model.type == .Rose {
            title = "🌹"        }
        else if model.type == .Bud{
            title = "🌱"
        }
        else{
            title = "🥀"
            
        }
        return title
    }
}
