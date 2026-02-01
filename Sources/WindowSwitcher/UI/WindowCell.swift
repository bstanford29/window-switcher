import SwiftUI

/// Individual window cell in the switcher
/// Design: Refined minimal with bold selection state
struct WindowCell: View {
    let window: WindowInfo
    let isSelected: Bool

    private let iconSize: CGFloat = 48
    private let cellWidth: CGFloat = 200
    private let cellHeight: CGFloat = 100

    // Design system colors
    private let accentColor = Color(red: 0.4, green: 0.6, blue: 1.0) // Soft electric blue
    private let selectedBg = Color(red: 0.2, green: 0.35, blue: 0.6).opacity(0.5)
    private let unselectedBg = Color.white.opacity(0.03)

    var body: some View {
        VStack(spacing: 8) {
            // App icon with glow effect when selected
            ZStack {
                if isSelected {
                    // Glow behind icon
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: iconSize + 20, height: iconSize + 20)
                        .blur(radius: 12)
                }

                Image(nsImage: window.appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

            VStack(spacing: 3) {
                // App name - bold, clear
                Text(window.ownerName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                    .lineLimit(1)

                // Window title - the actual content
                Text(window.windowTitle ?? "")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: cellWidth - 24, height: 28)
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? selectedBg : unselectedBg)

                // Subtle inner border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? accentColor.opacity(0.6) : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack(spacing: 0) {
        WindowCell(
            window: WindowInfo(
                id: 1,
                ownerPID: 1,
                ownerName: "Safari",
                windowTitle: "Apple - Start",
                appIcon: NSWorkspace.shared.icon(forFile: "/Applications/Safari.app"),
                bounds: .zero
            ),
            isSelected: true
        )
        WindowCell(
            window: WindowInfo(
                id: 2,
                ownerPID: 2,
                ownerName: "Finder",
                windowTitle: "Documents",
                appIcon: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"),
                bounds: .zero
            ),
            isSelected: false
        )
    }
    .padding()
    .background(Color.black.opacity(0.7))
}
