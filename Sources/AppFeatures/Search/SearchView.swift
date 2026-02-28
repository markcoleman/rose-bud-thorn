import SwiftUI
import CoreModels

public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @Binding private var selectedDayKey: LocalDayKey?

    public init(environment: AppEnvironment, selectedDayKey: Binding<LocalDayKey?>) {
        _viewModel = State(initialValue: SearchViewModel(environment: environment))
        _selectedDayKey = selectedDayKey
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        NavigationStack {
            VStack(spacing: 12) {
                TextField("Search text", text: $bindable.queryText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(DesignTokens.surface)
                    )

                HStack {
                    Toggle("Rose", isOn: $bindable.includeRose)
                    Toggle("Bud", isOn: $bindable.includeBud)
                    Toggle("Thorn", isOn: $bindable.includeThorn)
                }
                .toggleStyle(.button)

                Picker("Photos", selection: $bindable.photoFilter) {
                    ForEach(SearchViewModel.PhotoFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    Task { await bindable.runSearch() }
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("f", modifiers: [.command])

                if bindable.isSearching {
                    ProgressView()
                }

                List(bindable.results, id: \.self) { day in
                    NavigationLink(value: day) {
                        VStack(alignment: .leading) {
                            Text(day.isoDate)
                            Text(day.timeZoneID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)

                if let error = bindable.errorMessage {
                    ErrorBanner(message: error) {
                        bindable.errorMessage = nil
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Search")
            .navigationDestination(for: LocalDayKey.self) { day in
                DayDetailView(environment: bindable.environment, dayKey: day)
            }
        }
    }
}
