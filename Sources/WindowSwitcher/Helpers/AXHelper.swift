import AppKit
import ApplicationServices

/// Helper utilities for Accessibility API operations
enum AXHelper {

    /// Get all windows for an application
    static func getWindows(for pid: pid_t) -> [AXUIElement] {
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            return []
        }
        return windows
    }

    /// Get the title of an AXUIElement window
    static func getTitle(from element: AXUIElement) -> String? {
        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef) == .success else {
            return nil
        }
        return titleRef as? String
    }

    /// Get the position of an AXUIElement window
    static func getPosition(from element: AXUIElement) -> CGPoint? {
        var positionRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
              let positionValue = positionRef,
              CFGetTypeID(positionValue) == AXValueGetTypeID() else {
            return nil
        }

        var position = CGPoint.zero
        let axValue = positionValue as! AXValue  // Safe: verified by CFGetTypeID check
        guard AXValueGetValue(axValue, .cgPoint, &position) else {
            return nil
        }
        return position
    }

    /// Get the size of an AXUIElement window
    static func getSize(from element: AXUIElement) -> CGSize? {
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
              let sizeValue = sizeRef,
              CFGetTypeID(sizeValue) == AXValueGetTypeID() else {
            return nil
        }

        var size = CGSize.zero
        let axValue = sizeValue as! AXValue  // Safe: verified by CFGetTypeID check
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }
        return size
    }

    /// Get a generic attribute value from an AXUIElement
    static func getAttribute<T>(_ attribute: String, from element: AXUIElement) -> T? {
        var valueRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef) == .success else {
            return nil
        }
        return valueRef as? T
    }

    /// Raise a window to the front
    static func raiseWindow(_ element: AXUIElement) {
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)
    }

    /// Set a window as the main window
    static func setMainWindow(_ element: AXUIElement) {
        AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, kCFBooleanTrue)
    }
}
