import AppKit

/// Application delegate handling lifecycle and permissions
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check and request Accessibility permission
        checkAccessibilityPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up hotkey manager
        HotkeyManager.shared.stop()
    }

    private func checkAccessibilityPermission() {
        let permissionManager = PermissionManager.shared

        if !permissionManager.hasAccessibilityPermission {
            // Request permission - this shows the system dialog
            permissionManager.requestAccessibilityPermission()

            // Also show our custom alert with more context
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                permissionManager.showPermissionAlert()
            }
        }
    }
}
