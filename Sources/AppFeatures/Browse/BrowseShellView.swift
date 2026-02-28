import SwiftUI
import CoreModels

public struct BrowseShellView: View {
    @State private var viewModel: BrowseViewModel
    @Binding private var selectedDayKey: LocalDayKey?
    @State private var browseMode: BrowseMode = .calendar

    public enum BrowseMode: String, CaseIterable, Identifiable {
        case calendar
        case timeline

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .calendar: return "Calendar"
            case .timeline: return "Timeline"
            }
        }
    }

    public init(environment: AppEnvironment, selectedDayKey: Binding<LocalDayKey?>) {
        self._viewModel = State(initialValue: BrowseViewModel(environment: environment))
        self._selectedDayKey = selectedDayKey
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Browse Mode", selection: $browseMode) {
                    ForEach(BrowseMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch browseMode {
                case .calendar:
                    CalendarBrowseView(viewModel: viewModel, selectedDayKey: $selectedDayKey)
                case .timeline:
                    TimelineBrowseView(days: viewModel.days, selectedDayKey: $selectedDayKey)
                }

                if let selectedDayKey {
                    NavigationLink(value: selectedDayKey) {
                        Text("Open \(selectedDayKey.isoDate)")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.bottom, 14)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Browse")
            .navigationDestination(for: LocalDayKey.self) { dayKey in
                DayDetailView(environment: viewModel.environment, dayKey: dayKey)
            }
            .task {
                await viewModel.loadDays()
            }
        }
    }
}
