//
//  MonthView.swift
//  rose.bud.thorn
//
//  Created by Mark Coleman on 12/7/21.
//

import SwiftUI



struct WeekView: View {
    @Environment(\.calendar) var calendar

    var modelDate: MonthViewModel
    let week: Date

    init(week: Date, month: MonthViewModel) {
        self.week = week
        self.modelDate = month
    }

    private var days: [Date] {
        guard
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: week)
            else { return [] }
        return calendar.generateDates(
            inside: weekInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }

    
    var body: some View {
        HStack {
            ForEach(days, id: \.self) { date in
                HStack {
                    if self.calendar.isDate(self.week, equalTo: date, toGranularity: .month) {
                        DayView(date: date)
                    } else {
                        DayView(date: date).hidden()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Week of \(DateFormatter.monthAndYear.string(from: week))")
    }
}
