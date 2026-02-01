import AppKit
import ApplicationServices

/// Manages Accessibility permission requests and checks
final class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    /// Check if the app has Accessibility permission
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Request Accessibility permission, showing the system prompt
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Show an alert explaining why Accessibility permission is needed
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            WindowSwitcher needs Accessibility permission to:

            • Detect open windows across all applications
            • Switch focus between windows

            Please grant permission in System Settings > Privacy & Security > Accessibility.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    /// Open System Settings to the Accessibility pane
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
