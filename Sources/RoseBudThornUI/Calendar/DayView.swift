//
//  CalendarDayView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/6/21.
//

import SwiftUI
import RoseBudThornCore

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
               Text("Loading...")
                   .font(.rbtCaption)
                   .foregroundColor(DesignTokens.secondaryText)
                   .accessibilityLabel("Loading day data")
            }
            else{
                Button(action:{
                    showSheet = true
                }, label:{
                    Text(String(day))
                        .font(.rbtBody)
                        .foregroundColor(DesignTokens.primaryText)
                })
                .accessibleTouchTarget(
                    label: "Day \(day)", 
                    hint: self.viewModel.model!.hasEvent ? "Has events, tap to view or add new entry" : "No events, tap to add new entry"
                )
                .sheet(isPresented: $showSheet, content: {
                    AddNewRBTView(viewModel: self.viewModel)
                })
                .frame(width: DesignTokens.iconSize, height: DesignTokens.iconSize, alignment: .center)
                .background(self.viewModel.model!.hasEvent ? DesignTokens.successColor : DesignTokens.infoColor)
                .clipShape(Circle())
                .padding(.vertical, Spacing.xxSmall)
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
