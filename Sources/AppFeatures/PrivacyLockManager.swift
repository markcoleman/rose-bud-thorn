import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
public final class PrivacyLockManager {
    public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if !isEnabled {
                isLocked = false
            }
        }
    }

    public private(set) var isLocked: Bool
    public private(set) var lastError: String?

    private static let enabledKey = "privacy_lock_enabled"

    public init() {
        let enabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        self.isEnabled = enabled
        self.isLocked = enabled
    }

    public func lockIfNeeded() {
        guard isEnabled else { return }
        isLocked = true
    }

    public func unlock() async {
        guard isEnabled else {
            isLocked = false
            return
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            lastError = error?.localizedDescription ?? "Biometric authentication is unavailable."
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Rose, Bud, Thorn"
            )
            if success {
                isLocked = false
                lastError = nil
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}
