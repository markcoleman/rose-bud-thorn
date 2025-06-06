//
//  MonthView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/7/21.
//

import SwiftUI

struct MonthView: View {
    @Environment(\.calendar) var calendar

   
    let showHeader: Bool
    @ObservedObject var viewModel: MonthViewModel
    
    init(
        month: Date,
        showHeader: Bool = true
    ) {
        
        self.viewModel =  MonthViewModel(month: month)
        self.showHeader = showHeader
    }

   

    private var header: some View {
        let component = calendar.component(.month, from: viewModel.theMonth)
        let formatter = component == 1 ? DateFormatter.monthAndYear : .month
        return Text(formatter.string(from: viewModel.theMonth))
            .font(.title)
            .padding()
    }

    var body: some View {
        VStack {
            if showHeader {
                header
            }

            ForEach(self.viewModel.weeks, id: \.self) { week in
                WeekView(week: week, month: self.viewModel)
            }
        }.onAppear{
            self.viewModel.fetch()
        }
    }
}
