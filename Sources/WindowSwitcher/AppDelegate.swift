import AppKit

/// Application delegate handling lifecycle and permissions
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = SwitcherPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        NSLog("[WindowSwitcher] App launched")
        #endif

        // Set up status bar icon
        StatusBarManager.shared.setup()

        // Check and request Accessibility permission
        let hasPermission = checkAccessibilityPermission()
        #if DEBUG
        NSLog("[WindowSwitcher] Accessibility permission: \(hasPermission)")
        #else
        _ = hasPermission // Silence unused variable warning in release
        #endif

        // Set up hotkey handlers
        setupHotkeyHandlers()

        // Start listening for hotkeys
        HotkeyManager.shared.start()
        #if DEBUG
        NSLog("[WindowSwitcher] Hotkey manager started")
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
        StatusBarManager.shared.teardown()
    }

    private func checkAccessibilityPermission() -> Bool {
        let permissionManager = PermissionManager.shared

        if !permissionManager.hasAccessibilityPermission {
            #if DEBUG
            NSLog("[WindowSwitcher] Requesting accessibility permission...")
            #endif
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
            #if DEBUG
            NSLog("[WindowSwitcher] onShowSwitcher called")
            #endif
            self?.panelController.show()
        }

        hotkeyManager.onHideSwitcher = { [weak self] in
            #if DEBUG
            NSLog("[WindowSwitcher] onHideSwitcher called")
            #endif
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

        #if DEBUG
        NSLog("[WindowSwitcher] Hotkey handlers configured")
        #endif
    }
}
