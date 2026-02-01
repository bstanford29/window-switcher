import SwiftUI

/// Individual window cell in the switcher (Grid layout - Option B)
struct WindowCell: View {
    let window: WindowInfo
    let isSelected: Bool

    private let iconSize: CGFloat = 48
    private let cellWidth: CGFloat = 160
    private let cellHeight: CGFloat = 80

    var body: some View {
        VStack(spacing: 6) {
            // App icon
            Image(nsImage: window.appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            // App name
            Text(window.ownerName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            // Window title (subtitle)
            Text(window.windowTitle ?? "")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .frame(width: cellWidth - 24)
        }
        .frame(width: cellWidth, height: cellHeight)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
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
