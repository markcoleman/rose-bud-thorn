import SwiftUI
import CoreModels
#if !os(macOS)
import UIKit
#endif

public struct RootAppView: View {
    @State private var selectedSection: AppSection? = .today
    @State private var selectedTab: AppSection = .today
    @State private var selectedDayKey: LocalDayKey?
    @Environment(\.scenePhase) private var scenePhase

    private let environment: AppEnvironment
    @State private var lockManager = PrivacyLockManager()

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
            }
        }
        .onOpenURL(perform: handleDeepLink)
    }

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            TodayCaptureView(environment: environment)
                .tabItem { Label("Today", systemImage: AppSection.today.systemImage) }
                .tag(AppSection.today)

            BrowseShellView(environment: environment, selectedDayKey: $selectedDayKey)
                .tabItem { Label("Browse", systemImage: AppSection.browse.systemImage) }
                .tag(AppSection.browse)

            SummaryListView(environment: environment)
                .tabItem { Label("Summaries", systemImage: AppSection.summaries.systemImage) }
                .tag(AppSection.summaries)

            SearchView(environment: environment, selectedDayKey: $selectedDayKey)
                .tabItem { Label("Search", systemImage: AppSection.search.systemImage) }
                .tag(AppSection.search)

            SettingsView(lockManager: lockManager)
                .tabItem { Label("Settings", systemImage: AppSection.settings.systemImage) }
                .tag(AppSection.settings)
        }
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
            TodayCaptureView(environment: environment)
        case .browse:
            BrowseShellView(environment: environment, selectedDayKey: $selectedDayKey)
        case .summaries:
            SummaryListView(environment: environment)
        case .search:
            SearchView(environment: environment, selectedDayKey: $selectedDayKey)
        case .settings:
            SettingsView(lockManager: lockManager)
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
        case "browse":
            selectSection(.browse)
        case "summaries", "summary":
            selectSection(.summaries)
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

    #if !os(macOS)
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    #endif
}
