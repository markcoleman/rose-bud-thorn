import SwiftUI
import CoreModels

public struct BrowseShellView: View {
    @State private var viewModel: BrowseViewModel
    @Binding private var selectedDayKey: LocalDayKey?
    @State private var browseMode: BrowseMode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    private let isTimeCapsuleEnabled: Bool

    public enum BrowseMode: String, CaseIterable, Identifiable {
        case memories
        case calendar

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .memories: return "Memories"
            case .calendar: return "Calendar"
            }
        }
    }

    public init(environment: AppEnvironment, selectedDayKey: Binding<LocalDayKey?>) {
        let flags = environment.featureFlagStore.load(defaults: environment.featureFlags)
        self.isTimeCapsuleEnabled = flags.browseTimeCapsuleEnabled
        self._viewModel = State(initialValue: BrowseViewModel(environment: environment))
        self._selectedDayKey = selectedDayKey
        self._browseMode = State(initialValue: flags.browseTimeCapsuleEnabled ? .memories : .calendar)
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch browseMode {
                case .memories:
                    TimeCapsuleBrowseView(viewModel: viewModel, selectedDayKey: $selectedDayKey)
                case .calendar:
                    CalendarBrowseView(viewModel: viewModel, selectedDayKey: $selectedDayKey)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .top, spacing: 0) {
                if availableModes.count > 1 {
                    modePicker
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let selectedDayKey {
                    NavigationLink(value: selectedDayKey) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Day")
                                .font(.subheadline.weight(.semibold))
                            Text(contextualDayTitle(for: selectedDayKey))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 24)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Browse")
            .toolbar {
                ToolbarItem(placement: refreshPlacement) {
                    Button {
                        Task { await viewModel.refreshSnapshots() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .help("Refresh timeline")
                }
            }
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .navigationDestination(for: LocalDayKey.self) { dayKey in
                DayDetailView(environment: viewModel.environment, dayKey: dayKey)
            }
            .task {
                await viewModel.loadSnapshots()
                if selectedDayKey == nil {
                    selectedDayKey = viewModel.days.first
                }
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue == .active else { return }
                Task {
                    await viewModel.reloadOnForegroundIfNeeded()
                }
            }
        }
    }

    private var modePicker: some View {
        Picker("Browse Mode", selection: $browseMode) {
            ForEach(availableModes) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 24)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private var availableModes: [BrowseMode] {
        isTimeCapsuleEnabled ? BrowseMode.allCases : [.calendar]
    }

    private var refreshPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
        #else
        .topBarTrailing
        #endif
    }

    private func contextualDayTitle(for dayKey: LocalDayKey) -> String {
        let parts = dayKey.isoDate.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return dayKey.isoDate
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return dayKey.isoDate
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = calendar
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}
