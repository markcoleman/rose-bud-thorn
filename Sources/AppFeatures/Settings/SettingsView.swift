import SwiftUI
import CoreModels

public struct SettingsView: View {
    @State private var viewModel: PrivacyLockViewModel
    @State private var reminderPreferences: ReminderPreferences
    @State private var promptPreferences: PromptPreferences
    @State private var featureFlags: AppFeatureFlags

    private let environment: AppEnvironment

    public init(lockManager: PrivacyLockManager, environment: AppEnvironment) {
        self.environment = environment
        _viewModel = State(initialValue: PrivacyLockViewModel(manager: lockManager))
        _reminderPreferences = State(initialValue: environment.reminderPreferencesStore.load())
        _promptPreferences = State(initialValue: environment.promptPreferencesStore.load())
        _featureFlags = State(initialValue: environment.featureFlagStore.load(defaults: environment.featureFlags))
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        Form {
            Section("Reminders") {
                Toggle("Daily reminders", isOn: reminderEnabledBinding)

                if reminderPreferences.isEnabled {
                    Picker("Start time", selection: $reminderPreferences.startHour) {
                        ForEach(6..<23, id: \.self) { hour in
                            Text(timeLabel(hour)).tag(hour)
                        }
                    }

                    Picker("Fallback time", selection: $reminderPreferences.endHour) {
                        ForEach(12..<24, id: \.self) { hour in
                            Text(timeLabel(hour)).tag(hour)
                        }
                    }

                    Toggle("Include weekends", isOn: $reminderPreferences.includeWeekends)
                    Toggle("End-of-day fallback", isOn: $reminderPreferences.allowsEndOfDayFallback)
                }
            }
            .onChange(of: reminderPreferences) { _, newValue in
                environment.reminderPreferencesStore.save(newValue)
                Task {
                    await environment.analyticsStore.record(.reminderPreferencesUpdated)
                    await applyReminderPreferences(newValue)
                }
            }

            Section("Reflection Prompts") {
                Toggle("Enable prompts", isOn: promptEnabledBinding)

                if promptPreferences.isEnabled {
                    Picker("Theme", selection: $promptPreferences.themePreference) {
                        ForEach(PromptThemePreference.allCases, id: \.self) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }

                    Picker("Prompt mode", selection: $promptPreferences.selectionMode) {
                        ForEach(PromptSelectionMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }

                    ForEach(EntryType.allCases, id: \.self) { type in
                        Toggle("Show \(type.title) prompts", isOn: showPromptTypeBinding(type))
                    }
                }
            }
            .onChange(of: promptPreferences) { _, newValue in
                environment.promptPreferencesStore.save(newValue)
            }

            Section("Engagement Modules") {
                Toggle("Insights cards", isOn: $featureFlags.insightsEnabled)
                Toggle("On-this-day resurfacing", isOn: $featureFlags.resurfacingEnabled)
                Toggle("Weekly commitments", isOn: $featureFlags.commitmentsEnabled)
                Toggle("Modern OS26 visual style", isOn: $featureFlags.os26UIEnabled)

                Text("Feature module changes apply immediately to newly loaded screens.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .onChange(of: featureFlags) { _, newValue in
                environment.featureFlagStore.save(newValue)
            }

            Section("Privacy") {
                Toggle("Enable Lock", isOn: $bindable.manager.isEnabled)
                if bindable.manager.isEnabled {
                    Button("Test Unlock") {
                        Task { await bindable.requestUnlock() }
                    }
                }
                if let error = bindable.manager.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Storage") {
                Text("Data is stored locally in the app Documents directory and syncs through iCloud Drive when available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Shortcuts") {
                if let shortcutsURL = URL(string: "shortcuts://") {
                    Link("Open Shortcuts", destination: shortcutsURL)
                }
                Text("Add one-tap shortcuts for Rose, Bud, Thorn and weekly review actions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { reminderPreferences.isEnabled },
            set: { reminderPreferences.isEnabled = $0 }
        )
    }

    private var promptEnabledBinding: Binding<Bool> {
        Binding(
            get: { promptPreferences.isEnabled },
            set: { promptPreferences.isEnabled = $0 }
        )
    }

    private func showPromptTypeBinding(_ type: EntryType) -> Binding<Bool> {
        Binding(
            get: { !promptPreferences.hiddenTypes.contains(type) },
            set: { isShown in
                if isShown {
                    promptPreferences.hiddenTypes.remove(type)
                } else {
                    promptPreferences.hiddenTypes.insert(type)
                }
            }
        )
    }

    private func timeLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func applyReminderPreferences(_ preferences: ReminderPreferences) async {
        let now = Date.now
        let dayKey = environment.dayCalculator.dayKey(for: now)
        let summary = (try? await environment.completionTracker.summary(for: now, timeZone: .current)) ?? EntryCompletionSummary()
        if preferences.isEnabled {
            _ = await environment.analyticsStore.recordOncePerDay(.reminderScheduleEvaluated, dayKey: dayKey)
        }

        await environment.reminderScheduler.updateNotifications(
            for: dayKey,
            isComplete: summary.isTodayComplete,
            preferences: preferences
        )
    }
}
