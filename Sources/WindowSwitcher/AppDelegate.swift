import AppKit

/// Application delegate handling lifecycle and permissions
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = SwitcherPanelController()
    private var permissionTimer: Timer?
    private var hotkeyStarted = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.debug("App launched", category: .app)

        // Set up status bar icon
        StatusBarManager.shared.setup()

        // Set up hotkey handlers (but don't start yet)
        setupHotkeyHandlers()

        // Check and request Accessibility permission
        let hasPermission = checkAccessibilityPermission()
        Logger.debug("Accessibility permission: \(hasPermission)", category: .app)

        if hasPermission {
            // Permission already granted, start hotkeys immediately
            startHotkeys()
        } else {
            // Poll for permission until granted
            startPermissionPolling()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        permissionTimer = nil
        HotkeyManager.shared.stop()
        StatusBarManager.shared.teardown()
    }

    private func startHotkeys() {
        guard !hotkeyStarted else { return }
        hotkeyStarted = true

        HotkeyManager.shared.start()
        Logger.debug("Hotkey manager started", category: .app)
    }

    private func startPermissionPolling() {
        Logger.debug("Starting permission polling...", category: .app)

        // Poll every 0.5 seconds until permission is granted
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            if PermissionManager.shared.hasAccessibilityPermission {
                Logger.debug("Accessibility permission granted!", category: .app)
                self?.permissionTimer?.invalidate()
                self?.permissionTimer = nil
                self?.startHotkeys()
            }
        }
    }

    private func checkAccessibilityPermission() -> Bool {
        let permissionManager = PermissionManager.shared

        if !permissionManager.hasAccessibilityPermission {
            Logger.debug("Requesting accessibility permission...", category: .app)
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
            Logger.debug("onShowSwitcher called", category: .app)
            self?.panelController.show()
        }

        hotkeyManager.onHideSwitcher = { [weak self] in
            Logger.debug("onHideSwitcher called", category: .app)
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

        Logger.debug("Hotkey handlers configured", category: .app)
    }
}
