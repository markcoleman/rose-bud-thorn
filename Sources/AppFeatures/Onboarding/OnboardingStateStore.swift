import Foundation

public final class OnboardingStateStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = .standard,
        key: String = "OnboardingState.v1"
    ) {
        self.defaults = defaults
        self.key = key
    }

    public var hasCompletedFirstLaunchOnboarding: Bool {
        defaults.bool(forKey: key)
    }

    public func shouldPresentFirstLaunchOnboarding() -> Bool {
        !hasCompletedFirstLaunchOnboarding
    }

    public func markFirstLaunchOnboardingCompleted() {
        defaults.set(true, forKey: key)
    }

    public func reset() {
        defaults.removeObject(forKey: key)
    }
}
