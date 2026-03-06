import SwiftUI

private struct FloatingChromeHiddenPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

public extension View {
    func floatingChromeHidden(_ isHidden: Bool = true) -> some View {
        preference(key: FloatingChromeHiddenPreferenceKey.self, value: isHidden)
    }

    func onFloatingChromeHiddenPreference(_ action: @escaping (Bool) -> Void) -> some View {
        onPreferenceChange(FloatingChromeHiddenPreferenceKey.self, perform: action)
    }
}
