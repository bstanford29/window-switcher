import AppKit

/// Manages the menu bar status item
final class StatusBarManager {
    static let shared = StatusBarManager()

    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    private init() {}

    /// Set up the status bar icon
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            Logger.error("Failed to create status item button", category: .statusBar)
            return
        }

        // Use SF Symbol for the icon - "rectangle.on.rectangle.angled" is perfect for window switching
        // Falls back to a simple icon if SF Symbols unavailable
        if let image = NSImage(systemSymbolName: "rectangle.on.rectangle.angled", accessibilityDescription: "Window Switcher") {
            image.isTemplate = true  // Adapts to light/dark mode
            button.image = image
        } else {
            // Fallback: create a simple icon programmatically
            button.image = createFallbackIcon()
        }

        button.toolTip = "Window Switcher - Press ⌥Tab to switch windows"

        // Create menu
        menu = NSMenu()

        let aboutItem = NSMenuItem(title: "About Window Switcher", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu?.addItem(aboutItem)

        menu?.addItem(NSMenuItem.separator())

        let hotkeyItem = NSMenuItem(title: "⌥Tab to switch windows", action: nil, keyEquivalent: "")
        hotkeyItem.isEnabled = false
        menu?.addItem(hotkeyItem)

        let closeItem = NSMenuItem(title: "⌥Q to close selected app", action: nil, keyEquivalent: "")
        closeItem.isEnabled = false
        menu?.addItem(closeItem)

        menu?.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Window Switcher", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)

        statusItem?.menu = menu

        Logger.debug("Status bar icon created", category: .statusBar)
    }

    /// Create a fallback icon if SF Symbols aren't available
    private func createFallbackIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setStroke()

            // Draw two overlapping rectangles to represent windows
            let rect1 = NSRect(x: 2, y: 5, width: 10, height: 8)
            let rect2 = NSRect(x: 6, y: 2, width: 10, height: 8)

            let path1 = NSBezierPath(roundedRect: rect1, xRadius: 1, yRadius: 1)
            path1.lineWidth = 1.5
            path1.stroke()

            let path2 = NSBezierPath(roundedRect: rect2, xRadius: 1, yRadius: 1)
            path2.lineWidth = 1.5
            path2.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Window Switcher"
        alert.informativeText = "A Windows-style Alt+Tab window switcher for macOS.\n\nPress ⌥Tab to show the switcher.\nPress ⌥Q to close the selected app."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    /// Remove the status bar icon
    func teardown() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }
}
