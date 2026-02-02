import Foundation
import os.log

/// Centralized logging utility using os_log for better performance
/// Automatically strips debug logs in release builds
enum Logger {

    /// Subsystem identifier for unified logging
    private static let subsystem = "com.brandonstanford.windowswitcher"

    /// Log categories
    private static let appLog = OSLog(subsystem: subsystem, category: "app")
    private static let hotkeyLog = OSLog(subsystem: subsystem, category: "hotkey")
    private static let panelLog = OSLog(subsystem: subsystem, category: "panel")
    private static let windowLog = OSLog(subsystem: subsystem, category: "window")
    private static let statusBarLog = OSLog(subsystem: subsystem, category: "statusbar")

    /// Log categories for different components
    enum Category {
        case app
        case hotkey
        case panel
        case window
        case statusBar

        fileprivate var osLog: OSLog {
            switch self {
            case .app: return Logger.appLog
            case .hotkey: return Logger.hotkeyLog
            case .panel: return Logger.panelLog
            case .window: return Logger.windowLog
            case .statusBar: return Logger.statusBarLog
            }
        }
    }

    /// Log a debug message (only in DEBUG builds)
    static func debug(_ message: String, category: Category = .app) {
        #if DEBUG
        os_log("%{public}@", log: category.osLog, type: .debug, message)
        #endif
    }

    /// Log an info message
    static func info(_ message: String, category: Category = .app) {
        os_log("%{public}@", log: category.osLog, type: .info, message)
    }

    /// Log an error message
    static func error(_ message: String, category: Category = .app) {
        os_log("%{public}@", log: category.osLog, type: .error, message)
    }
}
