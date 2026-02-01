import SwiftUI

/// Main SwiftUI view for the window switcher (Grid layout - Option B)
struct SwitcherView: View {
    let windows: [WindowInfo]
    @Binding var selectedIndex: Int

    /// Calculate number of columns based on window count (max 4 columns)
    private var columns: Int {
        min(max(1, windows.count), 4)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(180), spacing: 8), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 8) {
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
        .padding(20)
        .frame(minWidth: 200, minHeight: 120)
        .background(
            ZStack {
                // Solid dark background for visibility
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
                // Blur effect on top
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 15)
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
