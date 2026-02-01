import AppKit
import CoreGraphics
import ApplicationServices

/// Service for enumerating and filtering windows
final class WindowService {
    static let shared = WindowService()

    private init() {}

    /// Minimum window size to be considered valid
    private let minimumSize: CGFloat = 50

    /// Get all switchable windows, sorted by most recently focused
    func getWindows() -> [WindowInfo] {
        // Reset cache for fresh enumeration
        axWindowsCache = [:]

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

    /// Cache of AX windows per app (pid -> [(title, position)])
    private var axWindowsCache: [pid_t: [(title: String, position: CGPoint)]] = [:]

    /// Get all window titles and positions for an app via Accessibility API
    private func getAXWindowsForApp(pid: pid_t) -> [(title: String, position: CGPoint)] {
        // Return cached if available
        if let cached = axWindowsCache[pid] {
            return cached
        }

        let axApp = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            // AX API can fail for various reasons (permission, app not responding, etc.)
            axWindowsCache[pid] = []
            return []
        }

        var windowData: [(title: String, position: CGPoint)] = []
        for window in windows {
            // Get title
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            let title = (titleResult == .success) ? (titleRef as? String ?? "") : ""

            // Get position for matching
            var positionRef: CFTypeRef?
            var position = CGPoint.zero
            if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
               let posValue = positionRef,
               CFGetTypeID(posValue) == AXValueGetTypeID() {
                let axValue = posValue as! AXValue  // Safe: verified by CFGetTypeID
                AXValueGetValue(axValue, .cgPoint, &position)
            }

            if !title.isEmpty {
                windowData.append((title: title, position: position))
            }
        }

        axWindowsCache[pid] = windowData
        return windowData
    }

    /// Get window title by matching position (more reliable than index matching)
    private func getTitleForWindow(pid: pid_t, bounds: CGRect) -> String? {
        let axWindows = getAXWindowsForApp(pid: pid)

        // Find window with matching position (within tolerance)
        let tolerance: CGFloat = 10
        for axWindow in axWindows {
            if abs(axWindow.position.x - bounds.origin.x) < tolerance &&
               abs(axWindow.position.y - bounds.origin.y) < tolerance {
                return axWindow.title
            }
        }

        // Fall back to first available title if position matching fails
        return axWindows.first?.title
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

        // Get window title via Accessibility API (matches by position for reliability)
        var windowTitle = getTitleForWindow(pid: ownerPID, bounds: bounds)

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
