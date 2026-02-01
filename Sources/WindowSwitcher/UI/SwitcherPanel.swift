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
        #if DEBUG
        NSLog("[SwitcherPanel] keyDown: keyCode=\(event.keyCode)")
        #endif
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
        #if DEBUG
        NSLog("[Panel] show() called")
        #endif

        // Refresh window list
        windows = WindowService.shared.getWindows()
        #if DEBUG
        NSLog("[Panel] Found \(windows.count) windows")
        #endif

        guard !windows.isEmpty else {
            #if DEBUG
            NSLog("[Panel] No windows found, returning")
            #endif
            return
        }

        #if DEBUG
        // Log window names (only in debug, window titles may contain sensitive info)
        for (i, w) in windows.prefix(8).enumerated() {
            NSLog("[Panel] Window \(i): \(w.ownerName)")
        }
        #endif

        // Reset selection to the second window (most recently used after current)
        // If there's only one window, select it
        selectedIndex = windows.count > 1 ? 1 : 0

        // Create panel if needed
        if panel == nil {
            panel = SwitcherPanel()
            #if DEBUG
            NSLog("[Panel] Created new panel")
            #endif
        }

        guard let panel = panel else {
            #if DEBUG
            NSLog("[Panel] ERROR: panel is nil")
            #endif
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
            #if DEBUG
            NSLog("[Panel] Created hosting view")
            #endif
        } else {
            hostingView?.rootView = view
        }

        // Size to fit content
        hostingView?.invalidateIntrinsicContentSize()
        var size = hostingView?.fittingSize ?? CGSize(width: 400, height: 200)
        // Ensure minimum size
        size.width = max(size.width, 300)
        size.height = max(size.height, 150)
        #if DEBUG
        NSLog("[Panel] Calculated size: \(size)")
        #endif

        // Center on the main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY - size.height / 2
            let frame = NSRect(x: x, y: y, width: size.width, height: size.height)
            panel.setFrame(frame, display: true)
            #if DEBUG
            NSLog("[Panel] Set frame: \(frame)")
            #endif
        } else {
            #if DEBUG
            NSLog("[Panel] ERROR: No main screen")
            #endif
        }

        // Show the panel
        panel.orderFrontRegardless()
        panel.makeKey()

        // Activate our app AFTER showing panel to receive key events (required for Q to close)
        NSApp.activate(ignoringOtherApps: true)

        // Make panel first responder
        panel.makeFirstResponder(panel.contentView)

        #if DEBUG
        NSLog("[Panel] Panel shown, isVisible: \(panel.isVisible), isKeyWindow: \(panel.isKeyWindow)")
        #endif

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

        // Activate the selected window (with error handling for closed windows)
        if let window = selectedWindow {
            // Small delay to ensure panel is hidden first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let success = WindowActivator.shared.activate(window)
                #if DEBUG
                if !success {
                    NSLog("[Panel] Window no longer exists, skipping activation: \(window.ownerName)")
                }
                #else
                _ = success // Silence unused variable warning in release
                #endif
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
    /// Note: Uses terminate() only to allow apps to show "save changes" dialogs
    func closeSelectedApp() {
        #if DEBUG
        NSLog("[Panel] closeSelectedApp() called - selectedIndex: \(selectedIndex), windows.count: \(windows.count)")
        #endif
        guard selectedIndex < windows.count else {
            #if DEBUG
            NSLog("[Panel] ERROR: selectedIndex out of bounds")
            #endif
            return
        }

        let window = windows[selectedIndex]
        let pid = window.ownerPID
        #if DEBUG
        NSLog("[Panel] Attempting to close: \(window.ownerName) (PID: \(pid))")
        #endif

        // Find the running application and terminate it
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            #if DEBUG
            NSLog("[Panel] App not found (already closed?), refreshing list")
            #endif
            refreshWindowList()
            return
        }

        // Check if already terminated
        if app.isTerminated {
            #if DEBUG
            NSLog("[Panel] App already terminated, refreshing list")
            #endif
            refreshWindowList()
            return
        }

        #if DEBUG
        NSLog("[Panel] Found app, calling terminate()")
        #endif
        // Use terminate() only - allows apps to show "save changes" dialogs
        // Do not use forceTerminate() to prevent potential data loss
        _ = app.terminate()

        // Refresh the window list after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshWindowList()
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
