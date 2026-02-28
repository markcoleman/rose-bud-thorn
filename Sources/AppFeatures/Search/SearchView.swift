import SwiftUI
import CoreModels

public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @Binding private var selectedDayKey: LocalDayKey?
    @FocusState private var isSearchFieldFocused: Bool

    public init(environment: AppEnvironment, selectedDayKey: Binding<LocalDayKey?>) {
        _viewModel = State(initialValue: SearchViewModel(environment: environment))
        _selectedDayKey = selectedDayKey
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        NavigationStack {
            GeometryReader { geometry in
                let horizontalPadding = DesignTokens.contentHorizontalPadding(for: geometry.size.width)

                List {
                    Section {
                        TextField("Search text", text: $bindable.queryText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFieldFocused)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(DesignTokens.surface)
                            )
                            .listRowInsets(
                                EdgeInsets(
                                    top: 10,
                                    leading: horizontalPadding,
                                    bottom: 6,
                                    trailing: horizontalPadding
                                )
                            )
                            .listRowBackground(Color.clear)

                        HStack {
                            Toggle("Rose", isOn: $bindable.includeRose)
                            Toggle("Bud", isOn: $bindable.includeBud)
                            Toggle("Thorn", isOn: $bindable.includeThorn)
                        }
                        .toggleStyle(.button)
                        .listRowInsets(
                            EdgeInsets(
                                top: 6,
                                leading: horizontalPadding,
                                bottom: 6,
                                trailing: horizontalPadding
                            )
                        )
                        .listRowBackground(Color.clear)

                        Picker("Media", selection: $bindable.photoFilter) {
                            ForEach(SearchViewModel.PhotoFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(
                            EdgeInsets(
                                top: 6,
                                leading: horizontalPadding,
                                bottom: 6,
                                trailing: horizontalPadding
                            )
                        )
                        .listRowBackground(Color.clear)

                        Button {
                            isSearchFieldFocused = false
                            Task { await bindable.runSearch() }
                        } label: {
                            Label("Search", systemImage: "magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut("f", modifiers: [.command])
                        .listRowInsets(
                            EdgeInsets(
                                top: 6,
                                leading: horizontalPadding,
                                bottom: 6,
                                trailing: horizontalPadding
                            )
                        )
                        .listRowBackground(Color.clear)

                        if bindable.isSearching {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowInsets(
                                    EdgeInsets(
                                        top: 8,
                                        leading: horizontalPadding,
                                        bottom: 8,
                                        trailing: horizontalPadding
                                    )
                                )
                                .listRowBackground(Color.clear)
                        }

                        if let error = bindable.errorMessage {
                            ErrorBanner(message: error) {
                                bindable.errorMessage = nil
                            }
                            .listRowInsets(
                                EdgeInsets(
                                    top: 8,
                                    leading: horizontalPadding,
                                    bottom: 8,
                                    trailing: horizontalPadding
                                )
                            )
                            .listRowBackground(Color.clear)
                        }
                    }
                    .textCase(nil)
                    .listSectionSeparator(.hidden)

                    Section("Results") {
                        if bindable.results.isEmpty {
                            ContentUnavailableView(
                                "No Results Yet",
                                systemImage: "magnifyingglass",
                                description: Text("Run a search to view matching days.")
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowInsets(
                                EdgeInsets(
                                    top: 12,
                                    leading: horizontalPadding,
                                    bottom: 12,
                                    trailing: horizontalPadding
                                )
                            )
                        } else {
                            ForEach(bindable.results, id: \.self) { day in
                                NavigationLink(value: day) {
                                    VStack(alignment: .leading) {
                                        Text(day.isoDate)
                                        Text(day.timeZoneID)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DesignTokens.backgroundGradient.ignoresSafeArea())
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isSearchFieldFocused = false
                        }
                    }
                }
            }
            .navigationTitle("Search")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationDestination(for: LocalDayKey.self) { day in
                DayDetailView(environment: bindable.environment, dayKey: day)
            }
        }
    }
}
