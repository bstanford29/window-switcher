import AppKit
import ApplicationServices

/// Service for activating (focusing) windows
final class WindowActivator {
    static let shared = WindowActivator()

    private init() {}

    /// Activate a window, bringing it to front and focusing its app
    func activate(_ window: WindowInfo) {
        // First, activate the owning application
        if let app = NSRunningApplication(processIdentifier: window.ownerPID) {
            app.activate(options: [.activateIgnoringOtherApps])
        }

        // Then raise the specific window using Accessibility API
        raiseWindow(window)
    }

    /// Raise a specific window using AXUIElement API
    private func raiseWindow(_ window: WindowInfo) {
        let appElement = AXUIElementCreateApplication(window.ownerPID)

        // Get the windows of this application
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success,
              let windowsArray = windowsRef as? [AXUIElement] else {
            return
        }

        // Find the matching window by comparing titles or position
        for axWindow in windowsArray {
            if windowMatches(axWindow, target: window) {
                // Raise the window
                AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)

                // Also set it as the main window
                AXUIElementSetAttributeValue(axWindow, kAXMainAttribute as CFString, kCFBooleanTrue)
                break
            }
        }
    }

    /// Check if an AXUIElement window matches our WindowInfo
    private func windowMatches(_ axWindow: AXUIElement, target: WindowInfo) -> Bool {
        // Try to match by title first
        var titleRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &titleRef) == .success,
           let title = titleRef as? String,
           let targetTitle = target.windowTitle,
           title == targetTitle {
            return true
        }

        // Fall back to matching by position
        var positionRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionRef) == .success {
            var position = CGPoint.zero
            if AXValueGetValue(positionRef as! AXValue, .cgPoint, &position) {
                // Allow some tolerance in position matching
                let tolerance: CGFloat = 5
                if abs(position.x - target.bounds.origin.x) < tolerance &&
                   abs(position.y - target.bounds.origin.y) < tolerance {
                    return true
                }
            }
        }

        // If we can't match precisely, try to match by size as additional heuristic
        var sizeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef) == .success {
            var size = CGSize.zero
            if AXValueGetValue(sizeRef as! AXValue, .cgSize, &size) {
                let tolerance: CGFloat = 5
                if abs(size.width - target.bounds.width) < tolerance &&
                   abs(size.height - target.bounds.height) < tolerance {
                    return true
                }
            }
        }

        return false
    }
}
