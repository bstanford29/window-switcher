import AppKit
import ApplicationServices

/// Service for activating (focusing) windows
final class WindowActivator {
    static let shared = WindowActivator()

    private init() {}

    /// Activate a window, bringing it to front and focusing its app
    /// Returns true if activation succeeded, false if the window/app no longer exists
    @discardableResult
    func activate(_ window: WindowInfo) -> Bool {
        // First, check if the app is still running
        guard let app = NSRunningApplication(processIdentifier: window.ownerPID) else {
            Logger.debug("App no longer running: \(window.ownerName) (PID: \(window.ownerPID))", category: .window)
            return false
        }

        // Check if app is terminated
        if app.isTerminated {
            Logger.debug("App is terminated: \(window.ownerName)", category: .window)
            return false
        }

        // Activate the owning application
        let activated = app.activate(options: [.activateIgnoringOtherApps])
        if !activated {
            Logger.debug("Failed to activate app: \(window.ownerName)", category: .window)
        }

        // Then raise the specific window using Accessibility API
        raiseWindow(window)
        return true
    }

    /// Raise a specific window using AXUIElement API
    private func raiseWindow(_ window: WindowInfo) {
        let windowsArray = AXHelper.getWindows(for: window.ownerPID)
        guard !windowsArray.isEmpty else { return }

        // Find the matching window by comparing titles or position
        for axWindow in windowsArray {
            if windowMatches(axWindow, target: window) {
                AXHelper.raiseWindow(axWindow)
                AXHelper.setMainWindow(axWindow)
                break
            }
        }
    }

    /// Check if an AXUIElement window matches our WindowInfo
    private func windowMatches(_ axWindow: AXUIElement, target: WindowInfo) -> Bool {
        // Try to match by title first
        if let title = AXHelper.getTitle(from: axWindow),
           let targetTitle = target.windowTitle,
           title == targetTitle {
            return true
        }

        // Fall back to matching by position
        if let position = AXHelper.getPosition(from: axWindow),
           GeometryHelper.positionsMatch(position, target.bounds.origin) {
            return true
        }

        // If we can't match precisely, try to match by size as additional heuristic
        if let size = AXHelper.getSize(from: axWindow),
           GeometryHelper.sizesMatch(size, target.bounds.size) {
            return true
        }

        return false
    }
}
