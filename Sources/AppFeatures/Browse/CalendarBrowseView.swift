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
                    .foregroundStyle(.secondary)
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
                Label("Older Entry", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(previous == nil)

            Button {
                guard let next else { return }
                selectedDayKey = next
            } label: {
                Label("Newer Entry", systemImage: "chevron.right")
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
        Text(String(day))
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : (hasEntry ? DesignTokens.accent : .secondary))
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                Circle()
                    .fill(
                        isSelected ? DesignTokens.accent :
                            (hasEntry ? DesignTokens.accent.opacity(0.18) : Color.clear)
                    )
            )
            .overlay(
                Circle()
                    .strokeBorder(hasEntry ? DesignTokens.accent.opacity(0.35) : Color.secondary.opacity(0.15), lineWidth: 1)
            )
    }
}
