import AppKit
import SwiftUI

/// Custom NSPanel for the window switcher overlay
final class SwitcherPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure panel behavior - use screenSaver level to appear above everything
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false

        // Allow the panel to become key for keyboard events
        becomesKeyOnlyIfNeeded = true
    }

    // Allow panel to receive key events
    override var canBecomeKey: Bool { true }

    // Handle key events directly
    override func keyDown(with event: NSEvent) {
        NSLog("[SwitcherPanel] keyDown: keyCode=\(event.keyCode)")
        // Let the HotkeyManager handle it via the event monitors
        super.keyDown(with: event)
    }
}

/// Controller for the switcher panel
final class SwitcherPanelController: ObservableObject {
    private var panel: SwitcherPanel?
    private var hostingView: NSHostingView<SwitcherView>?

    @Published var windows: [WindowInfo] = []
    @Published var selectedIndex: Int = 0

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    /// Show the switcher panel with the current windows
    func show() {
        NSLog("[Panel] show() called")

        // Refresh window list
        windows = WindowService.shared.getWindows()
        NSLog("[Panel] Found \(windows.count) windows")

        guard !windows.isEmpty else {
            NSLog("[Panel] No windows found, returning")
            return
        }

        // Log window names with titles
        for (i, w) in windows.prefix(8).enumerated() {
            NSLog("[Panel] Window \(i): \(w.ownerName) -> '\(w.windowTitle ?? "(nil)")'")
        }

        // Reset selection to the second window (most recently used after current)
        // If there's only one window, select it
        selectedIndex = windows.count > 1 ? 1 : 0

        // Create panel if needed
        if panel == nil {
            panel = SwitcherPanel()
            NSLog("[Panel] Created new panel")
        }

        guard let panel = panel else {
            NSLog("[Panel] ERROR: panel is nil")
            return
        }

        // Create the SwiftUI view with bindings
        let view = SwitcherView(
            windows: windows,
            selectedIndex: Binding(
                get: { [weak self] in self?.selectedIndex ?? 0 },
                set: { [weak self] in self?.selectedIndex = $0 }
            )
        )

        // Create or update hosting view
        if hostingView == nil {
            hostingView = NSHostingView(rootView: view)
            panel.contentView = hostingView
            NSLog("[Panel] Created hosting view")
        } else {
            hostingView?.rootView = view
        }

        // Size to fit content
        hostingView?.invalidateIntrinsicContentSize()
        var size = hostingView?.fittingSize ?? CGSize(width: 400, height: 200)
        // Ensure minimum size
        size.width = max(size.width, 300)
        size.height = max(size.height, 150)
        NSLog("[Panel] Calculated size: \(size)")

        // Center on the main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            let frame = NSRect(x: x, y: y, width: size.width, height: size.height)
            panel.setFrame(frame, display: true)
            NSLog("[Panel] Set frame: \(frame)")
        } else {
            NSLog("[Panel] ERROR: No main screen")
        }

        // Show the panel
        panel.orderFrontRegardless()
        panel.makeKey()

        // Activate our app AFTER showing panel to receive key events (required for Q to close)
        NSApp.activate(ignoringOtherApps: true)

        // Make panel first responder
        panel.makeFirstResponder(panel.contentView)

        NSLog("[Panel] Panel shown, isVisible: \(panel.isVisible), isKeyWindow: \(panel.isKeyWindow)")

        // Notify hotkey manager
        HotkeyManager.shared.switcherDidShow()
    }

    /// Hide the switcher panel and activate the selected window
    func hideAndActivate() {
        guard let panel = panel, panel.isVisible else { return }

        // Get the selected window before hiding
        let selectedWindow = selectedIndex < windows.count ? windows[selectedIndex] : nil

        // Hide the panel
        panel.orderOut(nil)

        // Notify hotkey manager
        HotkeyManager.shared.switcherDidHide()

        // Activate the selected window
        if let window = selectedWindow {
            // Small delay to ensure panel is hidden first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                WindowActivator.shared.activate(window)
            }
        }

        // Clear state
        windows = []
        selectedIndex = 0
    }

    /// Hide without activating (e.g., on Escape)
    func hide() {
        guard let panel = panel, panel.isVisible else { return }

        panel.orderOut(nil)
        HotkeyManager.shared.switcherDidHide()

        windows = []
        selectedIndex = 0
    }

    /// Cycle to the next window
    func cycleForward() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % windows.count
        updateView()
    }

    /// Cycle to the previous window
    func cycleBackward() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
        updateView()
    }

    /// Close the selected app and refresh the window list
    func closeSelectedApp() {
        NSLog("[Panel] closeSelectedApp() called - selectedIndex: \(selectedIndex), windows.count: \(windows.count)")
        guard selectedIndex < windows.count else {
            NSLog("[Panel] ERROR: selectedIndex out of bounds")
            return
        }

        let window = windows[selectedIndex]
        let pid = window.ownerPID
        NSLog("[Panel] Attempting to close: \(window.ownerName) (PID: \(pid))")

        // Find the running application and terminate it
        if let app = NSRunningApplication(processIdentifier: pid) {
            NSLog("[Panel] Found app, calling terminate()")
            let success = app.terminate()
            NSLog("[Panel] terminate() returned: \(success)")

            // Refresh the window list after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.refreshWindowList()
            }
        }
    }

    /// Refresh the window list and update view
    private func refreshWindowList() {
        windows = WindowService.shared.getWindows()

        if windows.isEmpty {
            // No more windows, hide the switcher
            hide()
            return
        }

        // Adjust selected index if needed
        if selectedIndex >= windows.count {
            selectedIndex = max(0, windows.count - 1)
        }

        updateView()
    }

    private func updateView() {
        // Update the SwiftUI view
        let view = SwitcherView(
            windows: windows,
            selectedIndex: Binding(
                get: { [weak self] in self?.selectedIndex ?? 0 },
                set: { [weak self] in self?.selectedIndex = $0 }
            )
        )
        hostingView?.rootView = view
    }
}
