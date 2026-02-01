import SwiftUI

/// Individual window cell in the switcher
struct WindowCell: View {
    let window: WindowInfo
    let isSelected: Bool

    private let iconSize: CGFloat = 64
    private let cellWidth: CGFloat = 120
    private let cellHeight: CGFloat = 100

    var body: some View {
        VStack(spacing: 8) {
            // App icon
            Image(nsImage: window.appIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            // Window title
            Text(window.displayTitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: cellWidth - 16)
        }
        .frame(width: cellWidth, height: cellHeight)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2)
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
