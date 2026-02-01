import SwiftUI

@main
struct WindowSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var panelController = SwitcherPanelController()

    init() {
        // Set up hotkey callbacks
        setupHotkeyHandlers()
    }

    var body: some Scene {
        // Menu bar extra (status bar icon)
        MenuBarExtra("WindowSwitcher", systemImage: "square.stack.3d.up") {
            VStack(alignment: .leading, spacing: 0) {
                Button("About WindowSwitcher") {
                    showAbout()
                }
                .keyboardShortcut("i", modifiers: .command)

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }

    private func setupHotkeyHandlers() {
        let hotkeyManager = HotkeyManager.shared

        hotkeyManager.onShowSwitcher = { [weak panelController] in
            panelController?.show()
        }

        hotkeyManager.onHideSwitcher = { [weak panelController] in
            panelController?.hideAndActivate()
        }

        hotkeyManager.onCycleForward = { [weak panelController] in
            panelController?.cycleForward()
        }

        hotkeyManager.onCycleBackward = { [weak panelController] in
            panelController?.cycleBackward()
        }

        // Start listening for hotkeys
        hotkeyManager.start()
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "WindowSwitcher"
        alert.informativeText = """
            A Windows-style Alt+Tab window switcher for macOS.

            Version 1.0

            Press Option+Tab to switch between windows.
            While holding Option, press Tab to cycle through windows.
            Release Option to activate the selected window.

            https://github.com/brandonstanford/windowswitcher
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
