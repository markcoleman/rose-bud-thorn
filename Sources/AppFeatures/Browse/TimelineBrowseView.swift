import SwiftUI
import CoreModels
#if os(iOS) && !targetEnvironment(macCatalyst)
import MessageUI
#endif

public struct TimelineBrowseView: View {
    @Bindable private var viewModel: BrowseViewModel
    @Binding private var selectedDayKey: LocalDayKey?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @State private var jumpDate: Date = .now
    @State private var showsJumpPicker = false
    @State private var lastScrubbedMonthKey: String?
    @State private var navigationSelection: TimelineNavigationSelection?
    @State private var sharePayload: DayShareCardPayload?
    @State private var shareLoadingDayKey: LocalDayKey?
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var isMessageComposerPresented = false
    @State private var isActivitySharePresented = false
    #endif

    public init(viewModel: BrowseViewModel, selectedDayKey: Binding<LocalDayKey?>) {
        self._viewModel = Bindable(viewModel)
        self._selectedDayKey = selectedDayKey
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header(proxy: proxy)
                        quickFilters

                        if !viewModel.availableYears.isEmpty {
                            YearRailView(
                                years: viewModel.availableYears,
                                selectedYear: Binding(
                                    get: { viewModel.selectedYear },
                                    set: { newValue in
                                        viewModel.setSelectedYear(newValue)
                                        scrollToFirstMonthForSelectedYear(proxy: proxy)
                                    }
                                )
                            )
                        }

                        content(proxy: proxy)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if !viewModel.timelineIndexItems.isEmpty && !viewModel.isLoading {
                    scrubRail(proxy: proxy)
                        .padding(.trailing, 6)
                        .padding(.vertical, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onAppear {
                jumpDate = viewModel.selectedDate
            }
        }
        .navigationDestination(item: $navigationSelection) { destination in
            DayDetailView(environment: viewModel.environment, dayKey: destination.dayKey)
        }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        .sheet(isPresented: $isMessageComposerPresented, onDismiss: {
            clearSharePayload()
        }) {
            if let payload = sharePayload {
                MessageComposerView(
                    bodyText: payload.messageBody,
                    attachmentURL: payload.outputURL,
                    attachmentTypeIdentifier: payload.outputTypeIdentifier
                ) { result in
                    switch result {
                    case .sent:
                        Task { await viewModel.environment.analyticsStore.record(.dayShareSent) }
                    case .failed:
                        Task { await viewModel.environment.analyticsStore.record(.dayShareFailed) }
                    case .cancelled:
                        break
                    }
                    isMessageComposerPresented = false
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $isActivitySharePresented, onDismiss: {
            clearSharePayload()
        }) {
            if let payload = sharePayload {
                ActivityShareSheetView(activityItems: [payload.outputURL, payload.messageBody]) { completed in
                    if completed {
                        Task { await viewModel.environment.analyticsStore.record(.dayShareSent) }
                    }
                }
                .ignoresSafeArea()
            }
        }
        #else
        .sheet(item: $sharePayload, onDismiss: {
            clearSharePayload()
        }) { payload in
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Share your card")
                        .font(.headline)
                    Text(payload.messageBody)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    ShareLink(item: payload.outputURL) {
                        Label("Share Card", systemImage: AppIcon.shareExport.systemName)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding()
                .navigationTitle("Share Day")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            clearSharePayload()
                        }
                    }
                }
            }
        }
        #endif
    }

    private func header(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Revisit your timeline")
                .font(.title2.weight(.bold))
                .foregroundStyle(DesignTokens.textPrimaryOnSurface)
            Text("Scroll day by day, jump by month, and share the moments that matter.")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.textSecondaryOnSurface)

            HStack(spacing: 10) {
                Button {
                    showsJumpPicker.toggle()
                } label: {
                    Label("Jump to Date", systemImage: AppIcon.sectionBrowse.systemName)
                }
                .buttonStyle(.bordered)

                if showsJumpPicker {
                    DatePicker(
                        "Jump to date",
                        selection: $jumpDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .onChange(of: jumpDate) { _, newDate in
                        jumpToDate(newDate, proxy: proxy)
                    }
                }
            }
        }
    }

    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BrowseQuickFilter.allCases) { filter in
                    Button {
                        viewModel.setQuickFilter(filter)
                    } label: {
                        Label(filter.title, systemImage: filter.systemImage)
                    }
                    .buttonStyle(FilterChipStyle(isActive: viewModel.quickFilter == filter))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func content(proxy: ScrollViewProxy) -> some View {
        if viewModel.isLoading && viewModel.sections.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ProgressView()
                Text("Loading your timeline...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 30)
        } else if viewModel.sections.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your timeline starts with today")
                    .font(.headline)
                Text("Capture your first Rose, Bud, or Thorn and this space will become your timeline.")
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)

                Button {
                    if let todayURL = URL(string: "rosebudthorn://today?source=browse-empty") {
                        openURL(todayURL)
                    }
                } label: {
                    Label("Capture Today", systemImage: AppIcon.sparkles.systemName)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(DesignTokens.surfaceElevated)
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(viewModel.sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        monthHeader(title: section.title)
                            .id(section.monthKey)

                        ForEach(section.days) { snapshot in
                            MemoryDayCardView(
                                snapshot: snapshot,
                                thumbnailURLs: snapshot.previewPhotoRefs.compactMap { ref in
                                    viewModel.photoURL(for: ref, day: snapshot.dayKey)
                                },
                                isShareInProgress: shareLoadingDayKey == snapshot.dayKey,
                                onOpen: {
                                    openDay(snapshot.dayKey)
                                },
                                onShare: {
                                    Task {
                                        await beginQuickShare(for: snapshot.dayKey)
                                    }
                                }
                            )
                            .id(snapshot.dayKey)
                        }
                    }
                }
            }
            .animation(reduceMotion ? nil : MotionTokens.smooth, value: viewModel.sections)
        }

        if let error = viewModel.errorMessage {
            ErrorBanner(message: error) {
                viewModel.errorMessage = nil
            }
        }
    }

    private func scrubRail(proxy: ScrollViewProxy) -> some View {
        GeometryReader { geometry in
            let count = max(viewModel.timelineIndexItems.count, 1)
            let rowHeight = geometry.size.height / CGFloat(count)

            VStack(spacing: 0) {
                ForEach(viewModel.timelineIndexItems) { item in
                    Button {
                        scrollToMonth(item.monthKey, proxy: proxy, recordAnalytics: true)
                    } label: {
                        Text(item.label)
                            .font(.caption2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(1)
                            .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                            .frame(maxWidth: .infinity, minHeight: rowHeight)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.accessibilityLabel)
                }
            }
            .frame(width: 38)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DesignTokens.surfaceElevated.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard rowHeight > 0 else { return }
                        let rawIndex = Int(value.location.y / rowHeight)
                        let index = min(max(rawIndex, 0), viewModel.timelineIndexItems.count - 1)
                        guard viewModel.timelineIndexItems.indices.contains(index) else { return }
                        let monthKey = viewModel.timelineIndexItems[index].monthKey
                        guard monthKey != lastScrubbedMonthKey else { return }
                        lastScrubbedMonthKey = monthKey
                        scrollToMonth(monthKey, proxy: proxy, recordAnalytics: true)
                    }
                    .onEnded { _ in
                        lastScrubbedMonthKey = nil
                    }
            )
        }
        .frame(width: 40)
    }

    private func monthHeader(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.weight(.semibold))
            LinearGradient(
                colors: [DesignTokens.accent.opacity(0.45), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
            .clipShape(Capsule())
        }
    }

    private func scrollToFirstMonthForSelectedYear(proxy: ScrollViewProxy) {
        guard let monthKey = viewModel.firstMonthKey(forYear: viewModel.selectedYear) else { return }
        scrollToMonth(monthKey, proxy: proxy, recordAnalytics: true)
    }

    private func scrollToMonth(_ monthKey: String, proxy: ScrollViewProxy, recordAnalytics: Bool) {
        if reduceMotion {
            proxy.scrollTo(monthKey, anchor: .top)
        } else {
            withAnimation(MotionTokens.quick) {
                proxy.scrollTo(monthKey, anchor: .top)
            }
        }

        guard recordAnalytics else { return }
        Task {
            await viewModel.environment.analyticsStore.record(.browseTimelineFastScrollUsed)
        }
    }

    private func jumpToDate(_ date: Date, proxy: ScrollViewProxy) {
        guard let nearest = viewModel.nearestEntry(to: date) else { return }
        selectedDayKey = nearest
        if reduceMotion {
            proxy.scrollTo(nearest, anchor: .top)
        } else {
            withAnimation(MotionTokens.quick) {
                proxy.scrollTo(nearest, anchor: .top)
            }
        }
        Task {
            await viewModel.environment.analyticsStore.record(.browseTimelineJumpToDateUsed)
        }
    }

    private func openDay(_ dayKey: LocalDayKey) {
        selectedDayKey = dayKey
        navigationSelection = TimelineNavigationSelection(dayKey: dayKey)
        Task {
            await viewModel.environment.analyticsStore.record(.browseDayDetailsOpened)
        }
    }

    private func beginQuickShare(for dayKey: LocalDayKey) async {
        guard shareLoadingDayKey == nil else { return }

        shareLoadingDayKey = dayKey
        defer { shareLoadingDayKey = nil }

        await viewModel.environment.analyticsStore.record(.browseTimelineQuickShareTapped)

        do {
            let payload = try await viewModel.makeSharePayload(for: dayKey)
            sharePayload = payload
            presentPreparedSharePayload()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func clearSharePayload() {
        guard let payload = sharePayload else { return }
        sharePayload = nil
        Task {
            await viewModel.disposeSharePayload(payload)
        }
    }

    private func presentPreparedSharePayload() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if MFMessageComposeViewController.canSendText() && MFMessageComposeViewController.canSendAttachments() {
            isMessageComposerPresented = true
            return
        }
        isActivitySharePresented = true
        #endif
    }
}

private struct FilterChipStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundStyle(isActive ? Color.white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? DesignTokens.accent : DesignTokens.surface)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(MotionTokens.quick, value: configuration.isPressed)
    }
}

private struct TimelineNavigationSelection: Hashable, Identifiable {
    let dayKey: LocalDayKey

    var id: String {
        "\(dayKey.isoDate)|\(dayKey.timeZoneID)"
    }
}
