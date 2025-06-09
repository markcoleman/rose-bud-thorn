//
//  ItemsService.swift
//  rose.bud.thorn (iOS)
//
//  Created by Mark Coleman on 1/4/22.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ApiData: Decodable{
    let message: String
    let data: [dayData?]
}
struct dayData : Decodable{
    let date: String
    let id: UUID?
    let bud: itemData
    let rose: itemData
    let thorn: itemData
}

struct itemData: Decodable{
    var id: String
    var mediaUrl: String
    var type: String
    var note: String? = ""
}

public class ItemService{
    public init(){
        
    }
    static var month: [String: DayModel] = [:]
    
    public func getItem(id: String) -> DayModel{
        let dateFormatter = DateFormatter()
        let dateFormat: String = "YYYY-MM-dd"
        dateFormatter.dateFormat = dateFormat
        let date1 = dateFormatter.date(from: id)!
        let dayModel = ItemService.month[id] ?? DayModel(date: date1, rose: Item(id: nil, mediaUrl: "", type: .Rose), bud: Item(id: nil, mediaUrl: "", type: .Bud), thorn: Item(id: nil, mediaUrl: "", type: .Thorn))
        
        return dayModel
    }
    
    public func saveDay(dayModel: DayModel){
        
        let dateFormat: String = "YYYY-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let date1Key = dateFormatter.string(from: dayModel.date)
        ItemService.month[date1Key] = dayModel
    }
    
    public func saveItem(item: Item){
        var theKey = ""
        ItemService.month.forEach { (key: String, value: DayModel) in
            
            if value.rose.id == item.id{
                theKey = key
            }
            if(value.bud.id == item.id){
                theKey = key
            }
            if(value.thorn.id == item.id){
                theKey = key
            }
        }
        var model = ItemService.month[theKey]
        
        if model!.rose.id == item.id{
            model?.rose = item
        }
        if(model!.bud.id == item.id){
            model?.bud = item
        }
        if(model!.thorn.id == item.id){
            model?.thorn = item
        }
        ItemService.month[theKey] = model
    }
    
    func fetchObjects(updatePlaces: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        guard let url = URL(string: "https://054c-70-44-110-213.ngrok.io/year") else { return }
        
        URLSession.shared.dataTask(with: url, completionHandler:updatePlaces).resume()
    }
    func parseData(data: ApiData){
        data.data.forEach{dayData in
            
            let dateFormatter = DateFormatter()
            let dateFormat: String = "YYYY-MM-dd"
            dateFormatter.dateFormat = dateFormat
            let date1 = dateFormatter.date(from: dayData!.date)!
            let rose = Item(id: UUID(uuidString: dayData!.rose.id), mediaUrl: (dayData?.rose.mediaUrl)!, type: .Rose, note:(dayData?.rose.note) ?? "")
            let bud = Item(id: UUID(uuidString: dayData!.bud.id), mediaUrl: (dayData?.bud.mediaUrl)!, type: .Bud, note:(dayData?.bud.note)  ?? "")
            let thorn = Item(id: UUID(uuidString: dayData!.thorn.id), mediaUrl: (dayData?.thorn.mediaUrl)!, type: .Thorn, note:(dayData?.thorn.note) ?? "")
            
            let day1 = DayModel(date: date1, rose: rose, bud: bud, thorn: thorn)
            
            
            ItemService.month[dayData!.date] = day1
        }
    }
}
