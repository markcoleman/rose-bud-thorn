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
        VStack(alignment: .leading, spacing: 10) {
            DatePicker("Pick a day", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .onChange(of: viewModel.selectedDate) { _, newDate in
                    selectedDayKey = viewModel.dayKey(for: newDate)
                }

            if let selectedDayKey {
                Text("Selected: \(selectedDayKey.isoDate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
