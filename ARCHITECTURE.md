# Window Switcher Architecture

A Windows-style Alt+Tab window switcher for macOS.

## Overview

Menu bar app that shows individual windows (not just apps) when Option+Tab is pressed.

## Tech Stack

| Component | Choice |
|-----------|--------|
| Language | Swift |
| UI | SwiftUI + AppKit (NSPanel) |
| Hotkeys | [HotKey](https://github.com/soffes/HotKey) library |
| Window enumeration | CGWindowListCopyWindowInfo |
| Window activation | AXUIElement (Accessibility API) |

## Project Structure

```
Sources/WindowSwitcher/
├── WindowSwitcherApp.swift     # @main entry, MenuBarExtra
├── AppDelegate.swift           # Lifecycle, permission checks, hotkey setup
├── Models/
│   └── WindowInfo.swift        # Window data model
├── Services/
│   ├── WindowService.swift     # Window enumeration & filtering
│   ├── HotkeyManager.swift     # Global hotkey registration
│   ├── WindowActivator.swift   # Focus/raise windows
│   └── PermissionManager.swift # Accessibility permission handling
└── UI/
    ├── SwitcherPanel.swift     # NSPanel + controller
    ├── SwitcherView.swift      # Main SwiftUI grid view
    └── WindowCell.swift        # Individual window cell
```

## Data Flow

```
Option+Tab pressed
       │
       ▼
HotkeyManager (detects via HotKey library)
       │
       ▼
AppDelegate.onShowSwitcher callback
       │
       ▼
SwitcherPanelController.show()
       │
       ├── WindowService.getWindows()
       │      └── CGWindowListCopyWindowInfo → filter → [WindowInfo]
       │
       ├── Create/update SwitcherView (SwiftUI)
       │
       └── SwitcherPanel.orderFrontRegardless()
              └── NSPanel at screenSaver level

Option released
       │
       ▼
HotkeyManager (detects via flags monitor)
       │
       ▼
SwitcherPanelController.hideAndActivate()
       │
       ├── Panel hidden
       │
       └── WindowActivator.activate(selectedWindow)
              ├── NSRunningApplication.activate()
              └── AXUIElement.performAction(kAXRaiseAction)
```

## Key Components

### HotkeyManager
- Registers Option+Tab via HotKey library (Carbon API wrapper)
- Monitors modifier key state via `NSEvent.addGlobalMonitorForEvents`
- Detects Tab presses while switcher is visible for cycling

### WindowService
- Uses `CGWindowListCopyWindowInfo` to enumerate windows
- Filters: layer 0 only, minimum size 50x50, excludes system processes
- Gets app icons via `NSWorkspace.shared.runningApplications`

### SwitcherPanel
- `NSPanel` subclass with `styleMask: [.borderless, .nonactivatingPanel]`
- Window level: `.screenSaver` (appears above everything)
- `collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary]`

### SwitcherView
- SwiftUI `LazyVGrid` with up to 4 columns
- Dark background with blur effect
- Blue highlight for selected window

## Permissions

| Permission | Required For | How to Grant |
|------------|--------------|--------------|
| Accessibility | Window enumeration, activation | System Settings > Privacy > Accessibility |
| Screen Recording | Thumbnails (future) | System Settings > Privacy > Screen Recording |

## App Bundle

The app runs as a menu bar agent (`LSUIElement=YES` in Info.plist):
- No dock icon
- Menu bar icon (stack symbol)
- Floating panel triggered by hotkey

Location: `WindowSwitcher.app/`

## Debugging Notes

### Window Titles Not Showing (Fixed)
**Root cause:** `CGWindowListCopyWindowInfo` with `kCGWindowName` returns `nil` for most windows without Screen Recording permission.

**Solution:** Use Accessibility API (`AXUIElement`) to get window titles:
```swift
let axApp = AXUIElementCreateApplication(pid)
AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute, &windowsRef)
// Then for each window:
AXUIElementCopyAttributeValue(window, kAXTitleAttribute, &titleRef)
```

**Affected components:** `WindowService.swift` - added `getWindowTitlesForApp()` and `getNextTitleForApp()` methods with caching.

### Tab Cycling While Holding Option (Fixed)
**Root cause:** HotKey library fires `keyDownHandler` on every Option+Tab press, not just the first.

**Solution:** Check if switcher is already visible in `handleHotkeyPressed()`:
```swift
if isSwitcherVisible {
    onCycleForward?()  // Cycle to next
} else {
    onShowSwitcher?()  // Show switcher
}
```

**Affected components:** `HotkeyManager.swift`

## Known Issues / Limitations

1. **Current Space only** - Only shows windows on current desktop
2. **No thumbnails** - Would require Screen Recording permission
3. **Some apps hide windows** - Electron apps may not expose all windows

## Build & Run

```bash
swift build
open WindowSwitcher.app
```

Or run directly:
```bash
swift run
```
