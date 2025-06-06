//
//  CalendarDayView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/6/21.
//

import SwiftUI

struct DayView: View {

    @State private var showSheet = false

    @ObservedObject
    var viewModel: DayViewModel
    
    init(date: Date) {
        self.viewModel = DayViewModel(date: date)
    }
    
    @Environment(\.calendar) var calendar
    var body: some View {
        let day = self.calendar.component(.day, from: self.viewModel.date)
        
        VStack{
            if(viewModel.loaded == false){
               Text("....")
            }
            else{
                Button(action:{
                    showSheet = true
                }, label:{
                    Text(String(day)).foregroundColor(Color.white)
                })
                    .sheet(isPresented: $showSheet, content: {
                        AddNewRBTView(viewModel: self.viewModel)
                    }).frame(width: 40, height: 40, alignment: .center)
                    .background(self.viewModel.model!.hasEvent ?  Color.green : Color.blue)
                    .clipShape(Circle())
                    .padding(.vertical, 4)
            }
        }.onAppear{
            self.viewModel.load()
        }
    }
}

/*
struct CalendarDayView_Previews:
    PreviewProvider {
    static var item: Item = Item(id: UUID(), mediaUrl: "", type: .Bud)
    static var items: [Item] = [
        item
    ]
    static var previews: some View {
        CalendarDayView(
            dayModel: DayModel(date: Date(), items:  items))
    }
}
*/
