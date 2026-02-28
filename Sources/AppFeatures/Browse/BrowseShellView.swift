import SwiftUI
import CoreModels

public struct BrowseShellView: View {
    @State private var viewModel: BrowseViewModel
    @Binding private var selectedDayKey: LocalDayKey?
    @State private var browseMode: BrowseMode = .calendar
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
            Group {
                switch browseMode {
                case .calendar:
                    CalendarBrowseView(viewModel: viewModel, selectedDayKey: $selectedDayKey)
                case .timeline:
                    TimelineBrowseView(days: viewModel.days, selectedDayKey: $selectedDayKey)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .top, spacing: 0) {
                modePicker
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedDayKey {
                    NavigationLink(value: selectedDayKey) {
                        Text("Open \(selectedDayKey.isoDate)")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 24)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Browse")
            .navigationDestination(for: LocalDayKey.self) { dayKey in
                DayDetailView(environment: viewModel.environment, dayKey: dayKey)
            }
            .task {
                await viewModel.loadDays()
            }
        }
    }

    private var modePicker: some View {
        Picker("Browse Mode", selection: $browseMode) {
            ForEach(BrowseMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 24)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }
}
