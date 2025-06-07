//
//  ContentView.swift
//  Shared
//
//  Created by Mark Coleman on 12/5/21.
//

import SwiftUI



struct ContentView: View {
    @Environment(\.calendar) var calendar
    private var year: DateInterval {
      calendar.dateInterval(of: .year, for: Date())!
    }
    private var items: [Item] = [
        Item(id: UUID(), mediaUrl: "", type: .Bud),
        Item(id: UUID(), mediaUrl: "", type: .Rose)
    ]
    
    
    
    
    var body: some View {
        TabView {
            CalendarView(interval: year)
                .tabItem {
                    Image(systemName: "calendar.circle.fill")
                    Text("All RBT")
                }
                .accessibilityLabel("Calendar view")
                .accessibilityHint("View all your Rose, Bud, and Thorn entries")
            ProfileView(viewModel: ProfileViewModel(model: ProfileModel()))
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .accessibilityLabel("Profile view")
                .accessibilityHint("View and manage your profile")
        }
        .background(DesignTokens.primaryBackground)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
