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

    private var hotKey: HotKey?
    private var flagsMonitor: Any?
    private var keyMonitor: Any?
    private var isSwitcherVisible = false

    private init() {}

    /// Start listening for the Option+Tab hotkey
    func start() {
        // Register Option+Tab hotkey
        hotKey = HotKey(key: .tab, modifiers: [.option])
        hotKey?.keyDownHandler = { [weak self] in
            self?.handleHotkeyPressed()
        }

        // Monitor for Option key release
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
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
    }

    /// Stop listening for hotkeys
    func stop() {
        hotKey = nil

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
        onShowSwitcher?()
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
