import AppKit
import CoreGraphics
import ApplicationServices

/// Service for enumerating and filtering windows
final class WindowService {
    static let shared = WindowService()

    private init() {}

    /// Minimum window size to be considered valid
    private let minimumSize: CGFloat = 50

    /// Cache of AXUIElement apps for window title lookup
    private var axAppCache: [pid_t: AXUIElement] = [:]

    /// Get all switchable windows, sorted by most recently focused
    func getWindows() -> [WindowInfo] {
        // Reset caches for fresh enumeration
        titlesCache = [:]
        titleIndexByApp = [:]

        // Note: .optionOnScreenOnly excludes minimized windows (same as Windows Alt+Tab)
        // To include minimized windows, would need .optionAll but that includes off-screen
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            #if DEBUG
            NSLog("[WindowService] Failed to get window list from CGWindowListCopyWindowInfo")
            #endif
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

    /// Cache of window titles per app (pid -> [title1, title2, ...])
    private var titlesCache: [pid_t: [String]] = [:]
    /// Track which title index we've used per app
    private var titleIndexByApp: [pid_t: Int] = [:]

    /// Get all window titles for an app via Accessibility API
    private func getWindowTitlesForApp(pid: pid_t) -> [String] {
        // Return cached if available
        if let cached = titlesCache[pid] {
            return cached
        }

        let axApp = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            // AX API can fail for various reasons (permission, app not responding, etc.)
            titlesCache[pid] = []
            return []
        }

        var titles: [String] = []
        for window in windows {
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            if titleResult == .success, let title = titleRef as? String, !title.isEmpty {
                titles.append(title)
            }
        }

        titlesCache[pid] = titles
        return titles
    }

    /// Get the next available title for an app
    private func getNextTitleForApp(pid: pid_t) -> String? {
        let titles = getWindowTitlesForApp(pid: pid)
        let index = titleIndexByApp[pid] ?? 0
        titleIndexByApp[pid] = index + 1

        guard index < titles.count else { return nil }
        return titles[index]
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

        // Get window title via Accessibility API (CGWindowList often returns nil)
        var windowTitle = getNextTitleForApp(pid: ownerPID)

        // Fall back to CGWindowList if AX didn't return anything
        if windowTitle == nil || windowTitle?.isEmpty == true {
            windowTitle = dict[kCGWindowName as String] as? String
        }

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
