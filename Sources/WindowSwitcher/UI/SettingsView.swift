import SwiftUI

/// Settings view for the menu bar dropdown
struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Settings")
                .font(.headline)
                .padding(.bottom, 4)

            Divider()

            // Hotkey section
            VStack(alignment: .leading, spacing: 8) {
                Text("Hotkey")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.secondary)
                    Text("Option + Tab")
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Text("Default")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            Divider()

            // Keyboard shortcuts help
            VStack(alignment: .leading, spacing: 6) {
                Text("Keyboard Shortcuts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ShortcutRow(keys: "⌥ Tab", action: "Show / cycle forward")
                ShortcutRow(keys: "⌥ ⇧ Tab", action: "Cycle backward")
                ShortcutRow(keys: "⌥ Q", action: "Close selected app")
                ShortcutRow(keys: "← → ↑ ↓", action: "Navigate")
                ShortcutRow(keys: "Esc", action: "Cancel")
                ShortcutRow(keys: "Release ⌥", action: "Activate window")
            }
        }
        .padding()
        .frame(width: 280)
    }
}

/// Row showing a keyboard shortcut
struct ShortcutRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            Text(action)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 300, height: 400)
}
