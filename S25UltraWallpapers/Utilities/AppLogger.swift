import Foundation
import os.log

/// Structured logger using os.Logger.
/// - .error and .fault are ALWAYS logged (never gated).
/// - .debug and .info are only logged in DEBUG builds.
struct AppLogger {
    // Subsystem = bundle identifier, category = logical component
    static let firebase   = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "Firebase")
    static let pagination = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "Pagination")
    static let premium    = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "Premium")
    static let cache      = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "Cache")
    static let ui         = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app", category: "UI")

    // Convenience wrappers that enforce the "always log errors" rule

    /// Always logs at .error level regardless of build configuration.
    static func error(_ logger: Logger, _ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    /// Only logs in DEBUG builds.
    static func debug(_ logger: Logger, _ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
}
