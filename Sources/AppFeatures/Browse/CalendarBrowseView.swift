import SwiftUI
import CoreModels

public struct CalendarBrowseView: View {
    @Bindable private var viewModel: BrowseViewModel
    @Binding private var selectedDayKey: LocalDayKey?

    public init(viewModel: BrowseViewModel, selectedDayKey: Binding<LocalDayKey?>) {
        self._viewModel = Bindable(viewModel)
        self._selectedDayKey = selectedDayKey
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DatePicker("Pick a day", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .onChange(of: viewModel.selectedDate) { _, newDate in
                    selectedDayKey = viewModel.dayKey(for: newDate)
                }

            entryJumpControls

            if let selectedDayKey {
                Text("Selected: \(selectedDayKey.isoDate)")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
            }

            monthEntryGrid

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: selectedDayKey) { _, newValue in
            guard let newValue, let date = viewModel.date(for: newValue) else { return }
            viewModel.selectedDate = date
        }
    }

    private var entryJumpControls: some View {
        let anchor = selectedDayKey ?? viewModel.nearestEntry(to: viewModel.selectedDate)
        let previous = viewModel.previousEntry(before: anchor)
        let next = viewModel.nextEntry(after: anchor)

        return HStack(spacing: 10) {
            Button {
                guard let previous else { return }
                selectedDayKey = previous
            } label: {
                Label("Older Entry", systemImage: AppIcon.navigateBackward.systemName)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(previous == nil)

            Button {
                guard let next else { return }
                selectedDayKey = next
            } label: {
                Label("Newer Entry", systemImage: AppIcon.navigateForward.systemName)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(next == nil)
        }
    }

    private var monthEntryGrid: some View {
        let highlightedDays = viewModel.entryDayNumbers(inMonthContaining: viewModel.selectedDate)
        let selected = viewModel.dayKey(for: viewModel.selectedDate).dayInt
        let calendar = Calendar(identifier: .gregorian)
        let dayRange = calendar.range(of: .day, in: .month, for: viewModel.selectedDate) ?? 1..<2
        let columns = Array(repeating: GridItem(.flexible(minimum: 28), spacing: 6), count: 7)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Days with entries this month")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(dayRange), id: \.self) { day in
                    dayCell(day: day, isSelected: day == selected, hasEntry: highlightedDays.contains(day))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DesignTokens.surfaceElevated)
        )
    }

    private func dayCell(day: Int, isSelected: Bool, hasEntry: Bool) -> some View {
        Button {
            guard let date = dateForDay(day) else { return }
            viewModel.selectedDate = date
            selectedDayKey = viewModel.dayKey(for: date)
        } label: {
            Text(String(day))
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    isSelected
                        ? DesignTokens.textOnAccent
                        : (hasEntry ? DesignTokens.accent : DesignTokens.textSecondaryOnSurface)
                )
                .frame(maxWidth: .infinity, minHeight: ControlTokens.minTouchTarget)
                .background(
                    Circle()
                        .fill(
                            isSelected
                                ? DesignTokens.accent
                                : (hasEntry ? DesignTokens.accent.opacity(0.18) : Color.clear)
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            hasEntry ? DesignTokens.focusStroke : DesignTokens.dividerSubtle,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .touchTargetMinSize(ControlTokens.minTouchTarget)
        .accessibilityLabel(
            hasEntry
                ? "Day \(day), has entry"
                : "Day \(day), no entry"
        )
        .accessibilityHint("Selects day \(day) in the current month.")
    }

    private func dateForDay(_ day: Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let base = viewModel.selectedDate
        let components = calendar.dateComponents([.year, .month], from: base)
        var dayComponents = DateComponents()
        dayComponents.year = components.year
        dayComponents.month = components.month
        dayComponents.day = day
        return calendar.date(from: dayComponents)
    }
}
