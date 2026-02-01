import SwiftUI

/// Main SwiftUI view for the window switcher
struct SwitcherView: View {
    let windows: [WindowInfo]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                WindowCell(
                    window: window,
                    isSelected: index == selectedIndex
                )
                .onTapGesture {
                    selectedIndex = index
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

/// NSVisualEffectView wrapper for SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    let sampleWindows = [
        WindowInfo(
            id: 1,
            ownerPID: 1,
            ownerName: "Safari",
            windowTitle: "Apple",
            appIcon: NSWorkspace.shared.icon(forFile: "/Applications/Safari.app"),
            bounds: .zero
        ),
        WindowInfo(
            id: 2,
            ownerPID: 2,
            ownerName: "Finder",
            windowTitle: "Documents",
            appIcon: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"),
            bounds: .zero
        ),
        WindowInfo(
            id: 3,
            ownerPID: 3,
            ownerName: "Terminal",
            windowTitle: "bash",
            appIcon: NSWorkspace.shared.icon(forFile: "/System/Applications/Utilities/Terminal.app"),
            bounds: .zero
        )
    ]

    return SwitcherView(windows: sampleWindows, selectedIndex: .constant(1))
        .padding(50)
        .background(Color.gray)
}
