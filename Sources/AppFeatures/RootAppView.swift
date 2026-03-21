import SwiftUI
import Foundation
import CoreModels
#if !os(macOS)
import UIKit
#endif

public struct RootAppView: View {
    @State private var selectedSection: AppSection? = .journal
    @State private var selectedTab: AppSection = .journal
    @State private var isSettingsPresented = false
    @State private var isFloatingChromeHidden = false
    @State private var captureLaunchRequest: CaptureLaunchRequest?
    @State private var journalRefreshToken = 0
    @State private var summaryLaunchRequest: SummaryLaunchRequest?
    @State private var onboardingPresentation: OnboardingPresentationSource?
    @State private var didApplyLaunchOverrides = false
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var isKeyboardVisible = false
    #endif
    @Environment(\.scenePhase) private var scenePhase

    private let environment: AppEnvironment
    private let onWillBecomeActive: (() -> Void)?
    @State private var lockManager = PrivacyLockManager()

    public init(
        environment: AppEnvironment,
        onWillBecomeActive: (() -> Void)? = nil
    ) {
        self.environment = environment
        self.onWillBecomeActive = onWillBecomeActive
    }

    public var body: some View {
        #if os(macOS)
        rootContent
            .sheet(item: $onboardingPresentation) { source in
                onboardingView(for: source)
            }
        #else
        rootContent
            .fullScreenCover(item: $onboardingPresentation) { source in
                onboardingView(for: source)
            }
        #endif
    }

    private var rootContent: some View {
        Group {
            if shouldUseSplitView {
                splitView
            } else {
                compactRootView
            }
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
                onWillBecomeActive?()
                journalRefreshToken &+= 1
                consumePendingIntentLaunchIfNeeded()
                presentFirstLaunchOnboardingIfNeeded()
            }
        }
        .onOpenURL(perform: handleDeepLink)
        .task {
            applyLaunchOverridesIfNeeded()
            await seedJournalUITestDataIfNeeded()
            onWillBecomeActive?()
            journalRefreshToken &+= 1
            consumePendingIntentLaunchIfNeeded()
            presentFirstLaunchOnboardingIfNeeded()
        }
    }

    private func onboardingView(for source: OnboardingPresentationSource) -> some View {
        OnboardingFlowView(
            countdownSeconds: onboardingCountdownSeconds,
            analyticsStore: environment.analyticsStore
        ) { reason in
            handleOnboardingDismiss(reason, source: source)
        }
    }

    private var compactRootView: some View {
        ZStack {
            switch selectedTab {
            case .insights:
                SummaryListView(
                    environment: environment,
                    summaryLaunchRequest: $summaryLaunchRequest,
                    onOpenSettings: {
                        isSettingsPresented = true
                    }
                )
            case .journal:
                JournalView(
                    environment: environment,
                    captureLaunchRequest: $captureLaunchRequest,
                    refreshTrigger: journalRefreshToken
                )
            }
        }
        .onFloatingChromeHiddenPreference { isHidden in
            isFloatingChromeHidden = isHidden
        }
        .safeAreaInset(edge: .bottom) {
            #if os(iOS) && !targetEnvironment(macCatalyst)
            if !isKeyboardVisible && !isFloatingChromeHidden {
                FloatingAppTabBar(selection: compactTabBinding)
            }
            #else
            if !isFloatingChromeHidden {
                FloatingAppTabBar(selection: compactTabBinding)
            }
            #endif
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                SettingsView(
                    lockManager: lockManager,
                    environment: environment,
                    onReplayOnboarding: replayOnboardingFromSettings
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            isSettingsPresented = false
                        }
                        .accessibilityIdentifier("settings-sheet-close")
                    }
                }
            }
        }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(MotionTokens.quick) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(MotionTokens.quick) {
                isKeyboardVisible = false
            }
        }
        #endif
    }

    private var compactTabBinding: Binding<AppSection> {
        Binding(
            get: { selectedTab == .insights ? .insights : .journal },
            set: { newValue in
                selectSection(newValue)
            }
        )
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
            sectionView(selectedSection ?? .journal)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: AppSection) -> some View {
        switch section {
        case .journal:
            JournalView(
                environment: environment,
                captureLaunchRequest: $captureLaunchRequest,
                refreshTrigger: journalRefreshToken
            )
        case .insights:
            SummaryListView(
                environment: environment,
                summaryLaunchRequest: $summaryLaunchRequest,
                onOpenSettings: {
                    isSettingsPresented = true
                }
            )
        }
    }

    private var lockOverlay: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            VStack(spacing: 16) {
                Image(systemName: AppIcon.lockShield.systemName)
                    .font(.largeTitle)
                Text("App Locked")
                    .font(.title3.weight(.semibold))
                Button("Unlock") {
                    Task { await lockManager.unlock() }
                }
                .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                .buttonStyle(.borderedProminent)
                if let error = lockManager.lastError {
                    Text(error)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "rosebudthorn" else { return }

        let route = (url.host?.lowercased() ?? url.pathComponents.dropFirst().first?.lowercased()) ?? ""
        let source = Self.source(from: url)
        switch route {
        case "capture", "today", "browse", "search", "journal":
            selectSection(.journal)
            if source == "share-extension" {
                journalRefreshToken &+= 1
            }
            captureLaunchRequest = Self.captureLaunchRequest(from: url)
        case "summaries", "summary", "insights", "engagement", "on-this-day", "resurfacing":
            selectSection(.insights)
            summaryLaunchRequest = Self.summaryLaunchRequest(from: url)
        case "weekly-review", "review":
            selectSection(.insights)
            summaryLaunchRequest = SummaryLaunchRequest(action: .startWeeklyReview, source: source)
        case "weekly-summary":
            selectSection(.insights)
            summaryLaunchRequest = SummaryLaunchRequest(action: .openCurrentWeeklySummary, source: source)
        case "settings":
            selectSection(.insights)
            isSettingsPresented = true
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

    private func applyLaunchOverridesIfNeeded() {
        guard !didApplyLaunchOverrides else { return }
        didApplyLaunchOverrides = true

        let launchArguments = ProcessInfo.processInfo.arguments
        if launchArguments.contains("-reset-onboarding") {
            environment.onboardingStateStore.reset()
        }
    }

    private func seedJournalUITestDataIfNeeded() async {
        let launchArguments = ProcessInfo.processInfo.arguments
        guard launchArguments.contains("-seed-journal-ui-data") else { return }

        let dayCalculator = environment.dayCalculator
        let todayDate = Date.now
        let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: todayDate) ?? todayDate

        let todayKey = dayCalculator.dayKey(for: todayDate, timeZone: .current)
        let yesterdayKey = dayCalculator.dayKey(for: yesterdayDate, timeZone: .current)

        do {
            var todayEntry = try await environment.entryStore.load(day: todayKey)
            if todayEntry.roseItem.shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                todayEntry.roseItem.shortText = "Seeded today rose"
                todayEntry.roseItem.updatedAt = .now
                todayEntry.updatedAt = .now
                try await environment.entryStore.save(todayEntry)
            }

            var yesterdayEntry = try await environment.entryStore.load(day: yesterdayKey)
            if yesterdayEntry.roseItem.shortText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                yesterdayEntry.roseItem.shortText = "Seeded yesterday rose"
                yesterdayEntry.budItem.shortText = "Seeded yesterday bud"
                yesterdayEntry.thornItem.shortText = "Seeded yesterday thorn"
                yesterdayEntry.roseItem.updatedAt = .now
                yesterdayEntry.budItem.updatedAt = .now
                yesterdayEntry.thornItem.updatedAt = .now
                yesterdayEntry.updatedAt = .now
                try await environment.entryStore.save(yesterdayEntry)
            }

            journalRefreshToken &+= 1
        } catch {
            // UI-test seeding is best effort and should never block launch.
        }
    }

    private func presentFirstLaunchOnboardingIfNeeded() {
        guard onboardingPresentation == nil else { return }
        guard environment.onboardingStateStore.shouldPresentFirstLaunchOnboarding() else { return }
        onboardingPresentation = .firstLaunch
    }

    private func replayOnboardingFromSettings() {
        Task {
            await environment.analyticsStore.record(.onboardingReplayOpened)
        }
        isSettingsPresented = false
        onboardingPresentation = .settingsReplay
    }

    private func handleOnboardingDismiss(
        _ reason: OnboardingDismissReason,
        source: OnboardingPresentationSource
    ) {
        if source == .firstLaunch {
            environment.onboardingStateStore.markFirstLaunchOnboardingCompleted()
        }

        onboardingPresentation = nil

        let event: LocalAnalyticsEvent
        switch reason {
        case .skipped:
            event = .onboardingSkipped
        case .completed, .closed, .autoCompleted:
            event = .onboardingCompleted
        }

        Task {
            await environment.analyticsStore.record(event)
        }
    }

    private var onboardingCountdownSeconds: Int {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-onboarding-countdown-seconds") else {
            return OnboardingFlowController.defaultCountdownSeconds
        }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex),
              let parsed = Int(arguments[valueIndex]),
              parsed > 0 else {
            return OnboardingFlowController.defaultCountdownSeconds
        }
        return parsed
    }

    private var shouldUseSplitView: Bool {
        #if os(macOS)
        return true
        #else
        if PlatformCapabilities.isMacCatalyst {
            return true
        }
        return UIDevice.current.userInterfaceIdiom == .pad
        #endif
    }
}

private enum OnboardingPresentationSource: String, Identifiable {
    case firstLaunch
    case settingsReplay

    var id: String { rawValue }
}
