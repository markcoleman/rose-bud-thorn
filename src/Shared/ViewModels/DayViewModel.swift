//
//  DayViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/20/21.
//

import Foundation

class DayViewModel: ObservableObject {
    
    @Published var model: DayModel? = nil
    var loaded: Bool
    var date: Date
    private var itemService: ItemService = ItemService()
    
    init(date: Date){
        self.loaded = false
        self.date = date
    }
    func dateString() -> String {
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "YYYY-MM-dd"
        let date1Key = dateFormatter.string(from: self.date)
        return date1Key
    }
    func load(){
        let dateFormat: String = "YYYY-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let date1Key = dateFormatter.string(from: date)
        let dayModel = itemService.getItem(id: date1Key)
        self.model = dayModel
        self.loaded = true
    }
    
    func save(){
        
        if self.model!.hasEvent == false {
            self.model!.bud.id = UUID()
            self.model!.thorn.id = UUID()
            self.model!.rose.id = UUID()
        }
        itemService.saveDay(dayModel: self.model!)
    }
    
}
