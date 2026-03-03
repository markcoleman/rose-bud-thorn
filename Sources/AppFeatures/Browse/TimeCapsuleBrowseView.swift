import SwiftUI
import CoreModels

public struct TimeCapsuleBrowseView: View {
    @Bindable private var viewModel: BrowseViewModel
    @Binding private var selectedDayKey: LocalDayKey?

    public init(viewModel: BrowseViewModel, selectedDayKey: Binding<LocalDayKey?>) {
        self._viewModel = Bindable(viewModel)
        self._selectedDayKey = selectedDayKey
    }

    public var body: some View {
        TimelineBrowseView(viewModel: viewModel, selectedDayKey: $selectedDayKey)
    }
}
