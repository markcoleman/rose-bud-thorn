import Foundation

public enum IntentLaunchStore {
    private static let pendingURLKey = "intent.pending.deep-link.v1"

    public static func queueDeepLink(_ url: URL, defaults: UserDefaults = .standard) {
        defaults.set(url.absoluteString, forKey: pendingURLKey)
    }

    public static func consumePendingURL(defaults: UserDefaults = .standard) -> URL? {
        guard let raw = defaults.string(forKey: pendingURLKey),
              let url = URL(string: raw) else {
            return nil
        }

        defaults.removeObject(forKey: pendingURLKey)
        return url
    }

    public static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: pendingURLKey)
    }
}
