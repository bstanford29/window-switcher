import SwiftUI

/// Main SwiftUI view for the window switcher
/// Design: Dark glass morphism with refined edges
struct SwitcherView: View {
    let windows: [WindowInfo]
    @Binding var selectedIndex: Int

    /// Calculate number of columns based on window count (max 4 columns)
    private var columns: Int {
        min(max(1, windows.count), 4)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.fixed(220), spacing: 12), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
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
        .padding(24)
        .frame(minWidth: 240, minHeight: 140)
        .background(
            ZStack {
                // Deep dark base
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.08).opacity(0.95))

                // Frosted glass effect
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // Subtle gradient overlay for depth
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.clear,
                                Color.black.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: 20)
        .shadow(color: Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.1), radius: 60, x: 0, y: 10)
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
