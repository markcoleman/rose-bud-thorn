import Foundation
import Observation

@MainActor
@Observable
public final class PrivacyLockViewModel {
    public var manager: PrivacyLockManager

    public init(manager: PrivacyLockManager) {
        self.manager = manager
    }

    public func requestUnlock() async {
        await manager.unlock()
    }
}
