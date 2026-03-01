import SwiftUI
import CoreModels

public struct TimeCapsuleBrowseView: View {
    @Bindable private var viewModel: BrowseViewModel
    @Binding private var selectedDayKey: LocalDayKey?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    public init(viewModel: BrowseViewModel, selectedDayKey: Binding<LocalDayKey?>) {
        self._viewModel = Bindable(viewModel)
        self._selectedDayKey = selectedDayKey
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    quickFilters

                    if !viewModel.availableYears.isEmpty {
                        YearRailView(
                            years: viewModel.availableYears,
                            selectedYear: Binding(
                                get: { viewModel.selectedYear },
                                set: { newValue in
                                    viewModel.setSelectedYear(newValue)
                                }
                            )
                        )
                    }

                    content
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: viewModel.selectedYear) { _, newValue in
                guard let monthKey = viewModel.firstMonthKey(forYear: newValue) else { return }
                if reduceMotion {
                    proxy.scrollTo(monthKey, anchor: .top)
                } else {
                    withAnimation(MotionTokens.smooth) {
                        proxy.scrollTo(monthKey, anchor: .top)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Revisit your moments")
                .font(.title2.weight(.bold))
            Text("Browse your past in chapters you can feel.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
    private var content: some View {
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
                Text("Capture your first Rose, Bud, or Thorn and this space will become your memory stream.")
                    .foregroundStyle(.secondary)

                Button {
                    if let todayURL = URL(string: "rosebudthorn://today?source=browse-empty") {
                        openURL(todayURL)
                    }
                } label: {
                    Label("Capture Today", systemImage: "sparkles")
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
                            MemoryDayCardView(snapshot: snapshot, isSelected: selectedDayKey == snapshot.dayKey) {
                                if reduceMotion {
                                    selectedDayKey = snapshot.dayKey
                                } else {
                                    withAnimation(MotionTokens.quick) {
                                        selectedDayKey = snapshot.dayKey
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .animation(reduceMotion ? nil : MotionTokens.smooth, value: viewModel.sections)
        }
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
