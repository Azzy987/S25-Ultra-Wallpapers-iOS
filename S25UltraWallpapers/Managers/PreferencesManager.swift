import Foundation

/// In-memory cache over UserDefaults.
/// All gets are zero-disk-I/O; all sets update memory first, then flush to UserDefaults on a background queue.
final class PreferencesManager {
    static let shared = PreferencesManager()

    // Keys preloaded into memory at init
    private static let preloadedKeys: [String] = [
        "hasCompletedOnboarding",
        "paywall_shown_after_onboarding",
        "notification_permission_requested",
        "privacy_policy_accepted",
        "isPremium",
        "premiumType",
        "is_premium_cached"
    ]

    private var cache: [String: Any] = [:]
    private let writeQueue = DispatchQueue(label: "com.app.preferences.write", qos: .utility)

    private init() {
        // Preload into memory once at startup
        for key in Self.preloadedKeys {
            cache[key] = UserDefaults.standard.object(forKey: key)
        }
    }

    // MARK: - Getters (zero disk I/O)

    func bool(forKey key: String) -> Bool {
        return cache[key] as? Bool ?? false
    }

    func string(forKey key: String) -> String? {
        return cache[key] as? String
    }

    func integer(forKey key: String) -> Int {
        return cache[key] as? Int ?? 0
    }

    func object(forKey key: String) -> Any? {
        return cache[key]
    }

    // MARK: - Setters (write to memory immediately, flush to disk async)

    func set(_ value: Bool, forKey key: String) {
        cache[key] = value
        writeQueue.async { UserDefaults.standard.set(value, forKey: key) }
    }

    func set(_ value: String?, forKey key: String) {
        cache[key] = value
        writeQueue.async { UserDefaults.standard.set(value, forKey: key) }
    }

    func set(_ value: Int, forKey key: String) {
        cache[key] = value
        writeQueue.async { UserDefaults.standard.set(value, forKey: key) }
    }

    func set(_ value: Any?, forKey key: String) {
        cache[key] = value
        writeQueue.async { UserDefaults.standard.set(value, forKey: key) }
    }

    func remove(forKey key: String) {
        cache.removeValue(forKey: key)
        writeQueue.async { UserDefaults.standard.removeObject(forKey: key) }
    }

    // MARK: - Refresh a key from disk (call if another process may have written)

    func refresh(key: String) {
        cache[key] = UserDefaults.standard.object(forKey: key)
    }
}
