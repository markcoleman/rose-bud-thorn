//
//  MonthViewModel.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/9/21.
//

import Foundation



class MonthViewModel: ObservableObject {
    
    @Published var weeks: [Date] = []
    var month: [String: DayModel] = [:]
    
    private let dateFormat: String = "YYYY-MM-dd"
    
    let theMonth: Date
    
    init(
        month: Date
    ) {
        self.theMonth = month
    }
    
    
    

    
    func searchFor(date: Date) -> (DayModel){
    
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = self.dateFormat
        let date1Key = dateFormatter.string(from: date)
        
        let dayModel = month[date1Key] ?? DayModel(date: date, rose: Item(id: nil, mediaUrl: "", type: .Rose), bud: Item(id: nil, mediaUrl: "", type: .Bud), thorn: Item(id: nil, mediaUrl: "", type: .Thorn))

        return dayModel
    }
    
    func fetch() {
        
        let calendar = Calendar.current
        
        if let monthInterval = calendar.dateInterval(of: .month, for: theMonth){
            self.weeks = calendar.generateDates(
                inside: monthInterval,
                matching: DateComponents(hour: 0, minute: 0, second: 0, weekday: calendar.firstWeekday))
        }
        else {
            weeks = []
        }
    }
}
