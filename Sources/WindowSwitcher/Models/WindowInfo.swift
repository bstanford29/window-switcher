import AppKit
import CoreGraphics

/// Represents a window that can be switched to
struct WindowInfo: Identifiable, Equatable {
    let id: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let windowTitle: String?
    let appIcon: NSImage
    let bounds: CGRect

    var displayTitle: String {
        if let title = windowTitle, !title.isEmpty {
            return title
        }
        return ownerName
    }

    static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
        lhs.id == rhs.id
    }
}
