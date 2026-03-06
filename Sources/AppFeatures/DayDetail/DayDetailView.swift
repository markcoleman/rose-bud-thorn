import SwiftUI
import CoreModels
import CoreDate

public struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel
    @State private var isPreparingDayShare = false
    @State private var sharePayload: DayShareCardPayload?
    @State private var isEditorPresented = false
    @State private var isRemoveConfirmationPresented = false
    #if os(iOS) && !targetEnvironment(macCatalyst)
    @State private var isActivitySharePresented = false
    #endif

    @Environment(\.dismiss) private var dismiss

    public init(environment: AppEnvironment, dayKey: LocalDayKey) {
        _viewModel = State(initialValue: DayDetailViewModel(environment: environment, dayKey: dayKey))
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        GeometryReader { geometry in
            let horizontalPadding = DesignTokens.contentHorizontalPadding(for: geometry.size.width)
            let contentWidth = max(280, geometry.size.width - (horizontalPadding * 2))

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    reflectionPicker(bindable)

                    DayPolaroidStackView(
                        entry: bindable.entry,
                        selectedType: bindable.selectedType,
                        availableWidth: contentWidth,
                        viewportHeight: geometry.size.height,
                        photoURL: { bindable.photoURL(for: $0) },
                        onSelectType: { bindable.selectedType = $0 }
                    )

                    if let error = bindable.errorMessage {
                        ErrorBanner(message: error) {
                            bindable.errorMessage = nil
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 14)
            }
        }
        .navigationTitle(PresentationFormatting.localizedDayTitle(for: bindable.dayKey))
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if bindable.isDayShareFeatureEnabled {
                    Button {
                        Task { await beginDayShare(model: bindable) }
                    } label: {
                        if isPreparingDayShare {
                            ProgressView()
                        } else {
                            Label("Share Memory", systemImage: AppIcon.shareExport.systemName)
                        }
                    }
                    .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                    .disabled(!bindable.isDayShareReady || isPreparingDayShare)
                    .accessibilityIdentifier("day-share-button")
                }

                Button {
                    isEditorPresented = true
                } label: {
                    Label("Edit", systemImage: AppIcon.editDay.systemName)
                }
                .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                .accessibilityIdentifier("day-edit-button")

                Menu {
                    Button(role: .destructive) {
                        isRemoveConfirmationPresented = true
                    } label: {
                        Label("Remove", systemImage: AppIcon.deleteDay.systemName)
                    }
                } label: {
                    Image(systemName: AppIcon.more.systemName)
                }
                .touchTargetMinSize(ControlTokens.minToolbarTouchTarget)
                .accessibilityLabel("More actions")
                .accessibilityIdentifier("day-more-actions")
            }
        }
        .task {
            await bindable.load()
        }
        .navigationDestination(isPresented: $isEditorPresented) {
            DayEditorView(viewModel: bindable)
        }
        .confirmationDialog(
            "Remove this day?",
            isPresented: $isRemoveConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                Task {
                    let removed = await bindable.removeDay()
                    if removed {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the Rose, Bud, and Thorn for \(dayMonthDayText(bindable.dayKey)).")
        }
        #if os(iOS) && !targetEnvironment(macCatalyst)
        .sheet(isPresented: $isActivitySharePresented, onDismiss: {
            clearSharePayload(bindable)
        }) {
            if let payload = sharePayload {
                ActivityShareSheetView(
                    activityItems: [payload.outputURL, payload.messageBody]
                ) { completed in
                    if completed {
                        Task { await bindable.recordDayShareSent() }
                    }
                }
                .ignoresSafeArea()
            }
        }
        #else
        .sheet(item: $sharePayload, onDismiss: {
            clearSharePayload(bindable)
        }) { payload in
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Share your memory stack")
                        .font(.headline)
                    Text(payload.messageBody)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    ShareLink(item: payload.outputURL) {
                        Label("Share Stack", systemImage: AppIcon.shareExport.systemName)
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
                            sharePayload = nil
                        }
                    }
                }
            }
        }
        #endif
    }

    private func reflectionPicker(_ model: DayDetailViewModel) -> some View {
        Picker("Reflection", selection: Binding(
            get: { model.selectedType },
            set: { newValue in
                withAnimation(MotionTokens.tabSwitch) {
                    model.selectedType = newValue
                }
            }
        )) {
            ForEach(EntryType.allCases, id: \.self) { type in
                Text(type.title).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DesignTokens.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DesignTokens.dividerSubtle, lineWidth: 1)
        )
        .accessibilityIdentifier("day-reflection-segmented")
    }

    private func beginDayShare(model: DayDetailViewModel) async {
        guard model.isDayShareReady else { return }

        isPreparingDayShare = true
        defer { isPreparingDayShare = false }

        await model.prepareShareSaveIfNeeded()
        if model.errorMessage != nil {
            return
        }

        do {
            let payload = try await model.makeDaySharePayload()
            sharePayload = payload
            presentPreparedSharePayload()
        } catch {
            model.errorMessage = error.localizedDescription
        }
    }

    private func clearSharePayload(_ model: DayDetailViewModel) {
        guard let payload = sharePayload else { return }
        sharePayload = nil
        Task {
            await model.disposeDaySharePayload(payload)
        }
    }

    private func presentPreparedSharePayload() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        isActivitySharePresented = true
        #endif
    }

    private func dayMonthDayText(_ dayKey: LocalDayKey) -> String {
        guard let date = DayKeyCalculator().date(for: dayKey) else {
            return dayKey.isoDate
        }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: dayKey.timeZoneID) ?? .current
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}
