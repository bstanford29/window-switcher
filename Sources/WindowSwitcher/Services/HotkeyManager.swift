import AppKit
import Carbon.HIToolbox
import HotKey

/// Manages global hotkey registration and modifier key monitoring
final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    /// Callback when switcher should be shown
    var onShowSwitcher: (() -> Void)?

    /// Callback when switcher should be hidden and selection activated
    var onHideSwitcher: (() -> Void)?

    /// Callback when Tab is pressed while switcher is visible
    var onCycleForward: (() -> Void)?

    /// Callback when Shift+Tab is pressed while switcher is visible
    var onCycleBackward: (() -> Void)?

    /// Callback when Q is pressed while switcher is visible (close app)
    var onCloseApp: (() -> Void)?

    private var optionTabHotKey: HotKey?
    private var optionQHotKey: HotKey?
    private var flagsMonitor: Any?
    private var keyMonitor: Any?
    private var globalKeyMonitor: Any?
    private var isSwitcherVisible = false

    private init() {}

    /// Start listening for the Option+Tab hotkey
    func start() {
        NSLog("[HotkeyManager] Starting hotkey registration...")

        // Register Option+Tab hotkey
        optionTabHotKey = HotKey(key: .tab, modifiers: [.option])

        NSLog("[HotkeyManager] HotKey object created: \(String(describing: optionTabHotKey))")
        NSLog("[HotkeyManager] KeyCombo: \(String(describing: optionTabHotKey?.keyCombo))")

        optionTabHotKey?.keyDownHandler = { [weak self] in
            NSLog("[HotkeyManager] >>> Option+Tab PRESSED! <<<")
            self?.handleHotkeyPressed()
        }

        optionTabHotKey?.keyUpHandler = {
            NSLog("[HotkeyManager] Option+Tab released")
        }

        NSLog("[HotkeyManager] Hotkey registered: Option+Tab")

        // Register Option+Q hotkey for closing apps
        optionQHotKey = HotKey(key: .q, modifiers: [.option])
        optionQHotKey?.keyDownHandler = { [weak self] in
            guard let self = self, self.isSwitcherVisible else { return }
            NSLog("[HotkeyManager] >>> Option+Q PRESSED! <<<")
            self.onCloseApp?()
        }
        NSLog("[HotkeyManager] Hotkey registered: Option+Q")

        // Monitor for Option key release
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        if flagsMonitor != nil {
            NSLog("[HotkeyManager] Global flags monitor installed")
        } else {
            NSLog("[HotkeyManager] WARNING: Failed to install global flags monitor")
        }

        // Also monitor local events (when our window is focused)
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            if event.type == .flagsChanged {
                self?.handleFlagsChanged(event)
            } else if event.type == .keyDown {
                return self?.handleKeyDown(event)
            }
            return event
        }

        NSLog("[HotkeyManager] Event monitors installed")

        // Global key monitor to detect Tab presses while switcher is visible
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.isSwitcherVisible else { return }

            // Tab key while Option is held = cycle
            if event.keyCode == UInt16(kVK_Tab) && event.modifierFlags.contains(.option) {
                if event.modifierFlags.contains(.shift) {
                    self.onCycleBackward?()
                } else {
                    self.onCycleForward?()
                }
            }

            // Escape to cancel
            if event.keyCode == UInt16(kVK_Escape) {
                self.onHideSwitcher?()
            }

            // Q to close selected app
            if event.keyCode == UInt16(kVK_ANSI_Q) {
                self.onCloseApp?()
            }
        }
        NSLog("[HotkeyManager] Global key monitor installed")
    }

    /// Stop listening for hotkeys
    func stop() {
        optionTabHotKey = nil
        optionQHotKey = nil

        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }

        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    /// Called when switcher becomes visible
    func switcherDidShow() {
        isSwitcherVisible = true
    }

    /// Called when switcher is hidden
    func switcherDidHide() {
        isSwitcherVisible = false
    }

    private func handleHotkeyPressed() {
        if isSwitcherVisible {
            // Already visible - cycle to next window
            onCycleForward?()
        } else {
            // Not visible - show switcher
            onShowSwitcher?()
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        // Check if Option key was released
        if isSwitcherVisible && !event.modifierFlags.contains(.option) {
            onHideSwitcher?()
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        guard isSwitcherVisible else { return event }

        // Check for Tab key
        if event.keyCode == UInt16(kVK_Tab) {
            if event.modifierFlags.contains(.shift) {
                onCycleBackward?()
            } else {
                onCycleForward?()
            }
            return nil // Consume the event
        }

        // Check for Escape to cancel
        if event.keyCode == UInt16(kVK_Escape) {
            onHideSwitcher?()
            return nil
        }

        // Check for Q to close selected app
        if event.keyCode == UInt16(kVK_ANSI_Q) {
            onCloseApp?()
            return nil
        }

        // Check for arrow keys
        if event.keyCode == UInt16(kVK_RightArrow) || event.keyCode == UInt16(kVK_DownArrow) {
            onCycleForward?()
            return nil
        }

        if event.keyCode == UInt16(kVK_LeftArrow) || event.keyCode == UInt16(kVK_UpArrow) {
            onCycleBackward?()
            return nil
        }

        return event
    }
}
