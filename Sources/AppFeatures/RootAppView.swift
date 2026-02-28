import SwiftUI
import CoreModels
#if !os(macOS)
import UIKit
#endif

public struct RootAppView: View {
    @State private var selectedSection: AppSection? = .today
    @State private var selectedTab: AppSection = .today
    @State private var selectedDayKey: LocalDayKey?
    @State private var captureLaunchRequest: CaptureLaunchRequest?
    @State private var summaryLaunchRequest: SummaryLaunchRequest?
    @Environment(\.scenePhase) private var scenePhase

    private let environment: AppEnvironment
    @State private var lockManager = PrivacyLockManager()
    private let tabOrder = AppSection.allCases

    public init(environment: AppEnvironment) {
        self.environment = environment
    }

    public var body: some View {
        Group {
            #if os(macOS)
            splitView
            #else
            if isPad {
                splitView
            } else {
                tabView
            }
            #endif
        }
        .overlay {
            if lockManager.isEnabled && lockManager.isLocked {
                lockOverlay
            }
        }
        .tint(DesignTokens.accent)
        .onChange(of: scenePhase) { _, newValue in
            if newValue != .active {
                lockManager.lockIfNeeded()
            } else {
                consumePendingIntentLaunchIfNeeded()
            }
        }
        .onOpenURL(perform: handleDeepLink)
        .task {
            consumePendingIntentLaunchIfNeeded()
        }
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            TodayCaptureView(environment: environment, captureLaunchRequest: $captureLaunchRequest)
                .tabItem { Label("Today", systemImage: AppSection.today.systemImage) }
                .tag(AppSection.today)

            BrowseShellView(environment: environment, selectedDayKey: $selectedDayKey)
                .tabItem { Label("Browse", systemImage: AppSection.browse.systemImage) }
                .tag(AppSection.browse)

            SummaryListView(environment: environment, summaryLaunchRequest: $summaryLaunchRequest)
                .tabItem { Label("Summaries", systemImage: AppSection.summaries.systemImage) }
                .tag(AppSection.summaries)

            SearchView(environment: environment, selectedDayKey: $selectedDayKey)
                .tabItem { Label("Search", systemImage: AppSection.search.systemImage) }
                .tag(AppSection.search)

            SettingsView(lockManager: lockManager, environment: environment)
                .tabItem { Label("Settings", systemImage: AppSection.settings.systemImage) }
                .tag(AppSection.settings)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(tabSwipeGesture, including: .all)
    }

    private var splitView: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Rose, Bud, Thorn")
            .safeAreaInset(edge: .top) {
                BrandMarkView()
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
        } detail: {
            sectionView(selectedSection ?? .today)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: AppSection) -> some View {
        switch section {
        case .today:
            TodayCaptureView(environment: environment, captureLaunchRequest: $captureLaunchRequest)
        case .browse:
            BrowseShellView(environment: environment, selectedDayKey: $selectedDayKey)
        case .summaries:
            SummaryListView(environment: environment, summaryLaunchRequest: $summaryLaunchRequest)
        case .search:
            SearchView(environment: environment, selectedDayKey: $selectedDayKey)
        case .settings:
            SettingsView(lockManager: lockManager, environment: environment)
        }
    }

    private var lockOverlay: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            VStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.largeTitle)
                Text("App Locked")
                    .font(.title3.weight(.semibold))
                Button("Unlock") {
                    Task { await lockManager.unlock() }
                }
                .buttonStyle(.borderedProminent)
                if let error = lockManager.lastError {
                    Text(error)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "rosebudthorn" else { return }

        let route = (url.host?.lowercased() ?? url.pathComponents.dropFirst().first?.lowercased()) ?? ""
        switch route {
        case "capture", "today":
            selectSection(.today)
            captureLaunchRequest = Self.captureLaunchRequest(from: url)
        case "browse":
            selectSection(.browse)
        case "summaries", "summary":
            selectSection(.summaries)
            summaryLaunchRequest = Self.summaryLaunchRequest(from: url)
        case "weekly-review", "review":
            selectSection(.summaries)
            summaryLaunchRequest = SummaryLaunchRequest(action: .startWeeklyReview, source: Self.source(from: url))
        case "weekly-summary":
            selectSection(.summaries)
            summaryLaunchRequest = SummaryLaunchRequest(action: .openCurrentWeeklySummary, source: Self.source(from: url))
        case "search":
            selectSection(.search)
        case "settings":
            selectSection(.settings)
        default:
            break
        }
    }

    private func selectSection(_ section: AppSection) {
        selectedSection = section
        selectedTab = section
    }

    static func captureLaunchRequest(from url: URL) -> CaptureLaunchRequest? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let typeValue = components.queryItems?
            .first(where: { $0.name.lowercased() == "type" })?
            .value?
            .lowercased()

        guard let typeValue, let type = EntryType(rawValue: typeValue) else {
            return nil
        }

        return CaptureLaunchRequest(type: type, source: source(from: url))
    }

    static func summaryLaunchRequest(from url: URL) -> SummaryLaunchRequest? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let actionValue = components.queryItems?
            .first(where: { $0.name.lowercased() == "action" })?
            .value?
            .lowercased()

        let periodValue = components.queryItems?
            .first(where: { $0.name.lowercased() == "period" })?
            .value?
            .lowercased()

        if let actionValue {
            switch actionValue {
            case "start-weekly-review", "weekly-review", "review":
                return SummaryLaunchRequest(action: .startWeeklyReview, source: source(from: url))
            case "open-current-weekly", "open-weekly", "open-current":
                return SummaryLaunchRequest(action: .openCurrentWeeklySummary, source: source(from: url))
            default:
                break
            }
        }

        if periodValue == "week" {
            return SummaryLaunchRequest(action: .openCurrentWeeklySummary, source: source(from: url))
        }

        return nil
    }

    private static func source(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        return components.queryItems?
            .first(where: { $0.name.lowercased() == "source" })?
            .value
    }

    private func consumePendingIntentLaunchIfNeeded() {
        guard let pendingURL = IntentLaunchStore.consumePendingURL() else {
            return
        }
        handleDeepLink(pendingURL)
    }

    private var tabSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 14, coordinateSpace: .local)
            .onEnded { value in
                handleTabSwipe(value)
            }
    }

    private func handleTabSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        let horizontalDominant = abs(horizontal) > abs(vertical) * DesignTokens.tabSwipeHorizontalDominanceRatio
        guard horizontalDominant else { return }

        let predicted = value.predictedEndTranslation.width
        let exceedsDistance = abs(horizontal) >= DesignTokens.tabSwipeMinimumTranslation
        let exceedsPredicted = abs(predicted) >= DesignTokens.tabSwipePredictedEndThreshold
        guard exceedsDistance || exceedsPredicted else { return }

        let effectiveTranslation = exceedsPredicted ? predicted : horizontal
        if effectiveTranslation < 0 {
            moveTab(step: 1)
        } else if effectiveTranslation > 0 {
            moveTab(step: -1)
        }
    }

    private func moveTab(step: Int) {
        guard let currentIndex = tabOrder.firstIndex(of: selectedTab) else { return }
        let nextIndex = currentIndex + step
        guard tabOrder.indices.contains(nextIndex) else { return }

        let nextTab = tabOrder[nextIndex]
        guard nextTab != selectedTab else { return }

        withAnimation(MotionTokens.tabSwitch) {
            selectedTab = nextTab
            selectedSection = nextTab
        }

        #if os(iOS)
        let feedback = UISelectionFeedbackGenerator()
        feedback.prepare()
        feedback.selectionChanged()
        #endif
    }

    #if !os(macOS)
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    #endif
}
