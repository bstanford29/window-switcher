import AppKit
import CoreGraphics

/// Service for enumerating and filtering windows
final class WindowService {
    static let shared = WindowService()

    private init() {}

    /// Minimum window size to be considered valid
    private let minimumSize: CGFloat = 50

    /// Get all switchable windows, sorted by most recently focused
    func getWindows() -> [WindowInfo] {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        // Build a map of running applications for icon lookup
        let runningApps = NSWorkspace.shared.runningApplications
        let appsByPID: [pid_t: NSRunningApplication] = Dictionary(
            uniqueKeysWithValues: runningApps.map { ($0.processIdentifier, $0) }
        )

        // Get our own PID to filter ourselves out
        let ownPID = ProcessInfo.processInfo.processIdentifier

        var windows: [WindowInfo] = []

        for windowDict in windowList {
            guard let windowInfo = parseWindowInfo(from: windowDict, appsByPID: appsByPID, ownPID: ownPID) else {
                continue
            }
            windows.append(windowInfo)
        }

        return windows
    }

    /// Parse a window dictionary into a WindowInfo, returning nil if it should be filtered out
    private func parseWindowInfo(
        from dict: [String: Any],
        appsByPID: [pid_t: NSRunningApplication],
        ownPID: pid_t
    ) -> WindowInfo? {
        // Get required fields
        guard let windowID = dict[kCGWindowNumber as String] as? CGWindowID,
              let ownerPID = dict[kCGWindowOwnerPID as String] as? pid_t,
              let layer = dict[kCGWindowLayer as String] as? Int,
              let boundsDict = dict[kCGWindowBounds as String] as? [String: CGFloat] else {
            return nil
        }

        // Filter: Only layer 0 (normal windows)
        guard layer == 0 else { return nil }

        // Filter: Skip our own windows
        guard ownerPID != ownPID else { return nil }

        // Parse bounds
        let bounds = CGRect(
            x: boundsDict["X"] ?? 0,
            y: boundsDict["Y"] ?? 0,
            width: boundsDict["Width"] ?? 0,
            height: boundsDict["Height"] ?? 0
        )

        // Filter: Skip tiny windows
        guard bounds.width >= minimumSize && bounds.height >= minimumSize else { return nil }

        // Filter: Skip windows with very low alpha (invisible)
        if let alpha = dict[kCGWindowAlpha as String] as? CGFloat, alpha < 0.1 {
            return nil
        }

        // Get owner name
        let ownerName = dict[kCGWindowOwnerName as String] as? String ?? "Unknown"

        // Filter: Skip system processes that shouldn't be switchable
        let excludedApps = ["Dock", "Window Server", "SystemUIServer", "Control Center", "Notification Center"]
        guard !excludedApps.contains(ownerName) else { return nil }

        // Get window title (may be nil or empty)
        let windowTitle = dict[kCGWindowName as String] as? String

        // Get app icon
        let appIcon: NSImage
        if let app = appsByPID[ownerPID], let icon = app.icon {
            appIcon = icon
        } else {
            appIcon = NSWorkspace.shared.icon(forFile: "/Applications")
        }

        return WindowInfo(
            id: windowID,
            ownerPID: ownerPID,
            ownerName: ownerName,
            windowTitle: windowTitle,
            appIcon: appIcon,
            bounds: bounds
        )
    }
}
