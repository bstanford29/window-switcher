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
            #if DEBUG
            NSLog("[WindowActivator] App no longer running: \(window.ownerName) (PID: \(window.ownerPID))")
            #endif
            return false
        }

        // Check if app is terminated
        if app.isTerminated {
            #if DEBUG
            NSLog("[WindowActivator] App is terminated: \(window.ownerName)")
            #endif
            return false
        }

        // Activate the owning application
        let activated = app.activate(options: [.activateIgnoringOtherApps])
        #if DEBUG
        if !activated {
            NSLog("[WindowActivator] Failed to activate app: \(window.ownerName)")
        }
        #else
        _ = activated // Silence unused variable warning in release
        #endif

        // Then raise the specific window using Accessibility API
        raiseWindow(window)
        return true
    }

    /// Check if a window still exists (app is running and not terminated)
    func windowExists(_ window: WindowInfo) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: window.ownerPID) else {
            return false
        }
        return !app.isTerminated
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
        if AXUIElementCopyAttributeValue(axWindow, kAXPositionAttribute as CFString, &positionRef) == .success,
           let positionValue = positionRef,
           CFGetTypeID(positionValue) == AXValueGetTypeID() {
            var position = CGPoint.zero
            let axValue = positionValue as! AXValue  // Safe: verified by CFGetTypeID check above
            if AXValueGetValue(axValue, .cgPoint, &position) {
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
        if AXUIElementCopyAttributeValue(axWindow, kAXSizeAttribute as CFString, &sizeRef) == .success,
           let sizeValue = sizeRef,
           CFGetTypeID(sizeValue) == AXValueGetTypeID() {
            var size = CGSize.zero
            let axValue = sizeValue as! AXValue  // Safe: verified by CFGetTypeID check above
            if AXValueGetValue(axValue, .cgSize, &size) {
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
