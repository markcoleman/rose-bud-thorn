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
                            Text("View Day Details")
                                .font(.subheadline.weight(.semibold))
                            Text(PresentationFormatting.localizedDayTitle(for: selectedDayKey))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("View day details")
                    .accessibilityHint("Opens the full entry editor for \(PresentationFormatting.localizedDayTitle(for: selectedDayKey)).")
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Task { await viewModel.environment.analyticsStore.record(.browseDayDetailsOpened) }
                        }
                    )
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
}
