import SwiftUI

public struct SettingsView: View {
    @State private var viewModel: PrivacyLockViewModel

    public init(lockManager: PrivacyLockManager) {
        _viewModel = State(initialValue: PrivacyLockViewModel(manager: lockManager))
    }

    public var body: some View {
        @Bindable var bindable = viewModel

        Form {
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
        }
        .navigationTitle("Settings")
    }
}
