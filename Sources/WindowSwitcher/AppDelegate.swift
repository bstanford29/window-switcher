import AppKit
import os.log

private let logger = Logger(subsystem: "com.brandonstanford.windowswitcher", category: "App")

/// Application delegate handling lifecycle and permissions
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = SwitcherPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[WindowSwitcher] App launched")

        // Check and request Accessibility permission
        let hasPermission = checkAccessibilityPermission()
        NSLog("[WindowSwitcher] Accessibility permission: \(hasPermission)")

        // Set up hotkey handlers
        setupHotkeyHandlers()

        // Start listening for hotkeys
        HotkeyManager.shared.start()
        NSLog("[WindowSwitcher] Hotkey manager started")
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
    }

    private func checkAccessibilityPermission() -> Bool {
        let permissionManager = PermissionManager.shared

        if !permissionManager.hasAccessibilityPermission {
            NSLog("[WindowSwitcher] Requesting accessibility permission...")
            permissionManager.requestAccessibilityPermission()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                permissionManager.showPermissionAlert()
            }
            return false
        }
        return true
    }

    private func setupHotkeyHandlers() {
        let hotkeyManager = HotkeyManager.shared

        hotkeyManager.onShowSwitcher = { [weak self] in
            NSLog("[WindowSwitcher] onShowSwitcher called")
            self?.panelController.show()
        }

        hotkeyManager.onHideSwitcher = { [weak self] in
            NSLog("[WindowSwitcher] onHideSwitcher called")
            self?.panelController.hideAndActivate()
        }

        hotkeyManager.onCycleForward = { [weak self] in
            self?.panelController.cycleForward()
        }

        hotkeyManager.onCycleBackward = { [weak self] in
            self?.panelController.cycleBackward()
        }

        hotkeyManager.onCloseApp = { [weak self] in
            self?.panelController.closeSelectedApp()
        }

        NSLog("[WindowSwitcher] Hotkey handlers configured")
    }
}
