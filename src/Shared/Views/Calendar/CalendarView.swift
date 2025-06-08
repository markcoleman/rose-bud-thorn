import SwiftUI

internal extension DateFormatter {
    static var month: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }

    static var monthAndYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}
public extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }

        return dates
    }
}

struct CalendarView: View {
    @Environment(\.calendar) var calendar

    let interval: DateInterval
    @ObservedObject var thing = AThing()

    init(interval: DateInterval) {
        self.interval = interval
    }

    private var months: [Date] {
        calendar.generateDates(
            inside: interval,
            matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
        )
    }

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    if(thing.dataIsLoaded){
                        ForEach(months, id: \.self) { month in
                            MonthView(month: month)
                        }
                    }
                    else{
                        Text("Loading....")
                            .font(.rbtBody)
                            .foregroundColor(DesignTokens.secondaryText)
                            .accessibilityLabel("Loading calendar data")
                    }
                }.onAppear{
                    scrollView.scrollTo(Calendar.current.dateComponents([.month], from: Date()).month)
                    
                    // Auto-start Live Activity if it's not running and user hasn't explicitly disabled it
                    #if os(iOS)
                    if #available(iOS 16.1, *) {
                        if !LiveActivityManager.shared.isLiveActivityRunning {
                            // Check if user has interacted with Live Activity before (stored in UserDefaults)
                            let hasSeenLiveActivity = UserDefaults.standard.bool(forKey: "HasSeenLiveActivity")
                            if !hasSeenLiveActivity {
                                UserDefaults.standard.set(true, forKey: "HasSeenLiveActivity")
                                DailySummaryService.shared.startLiveActivityWithCurrentCounts()
                            }
                        }
                    }
                    #endif
                }
            }
        }
    }
}
class AThing: ObservableObject {
    @Published var dataIsLoaded: Bool = false
    init(){
        let service = ItemService()
        service.fetchObjects{data, response, error in
            guard let data = data, error == nil else { return }
                    
            do {
                let jsonData = try JSONDecoder().decode(ApiData.self, from: data)
                service.parseData(data: jsonData)
                DispatchQueue.main.async {
                    self.dataIsLoaded = true
                }                         
            } catch let jsonErr {
                print("failed to decode json:", jsonErr)
                
            }
        }
    }
}
